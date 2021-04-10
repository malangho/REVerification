pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;

import "../libs/Initializable.sol";

import "./CertificateDefinitions.sol";
import "./ICertificateLogic.sol";
import "./RoleManagementMin.sol";

contract REVerificationMin is Initializable, RoleManagementMin{
    
    
    bool private _initialized;
    address private userLogicAddress;
    address certificateLogicAddress;
    ICertificateLogic private certificateLogic;
    
    enum Status {
        Open,
        Verified
    }
    
    struct Framework {
        address cpo;
        address emsp;
        address evuser;
        string cdrId;
        uint16 energy;
        uint256[] verifyingCertificates;
        uint256 verifiedEnergy;
        uint8 Status;
    }
    
    Framework[] private FrameworkContracts;
    mapping(address => uint[]) private userIndex;
    mapping(address => uint[]) private CPOIndex;
    mapping(address => uint[]) private EMSPIndex;
    
    function initialize(address userlogic, address _certificateLogic) public initializer {
        RoleManagementMin.initialize(userlogic);
        userLogicAddress = userlogic;
        certificateLogicAddress = _certificateLogic;
        certificateLogic = ICertificateLogic(_certificateLogic);
        _initialized=true;
    }
    
    function createREVerification(
        address _cpo,
        address _emsp,
        string calldata _cdrId,
        uint16 _energy
    ) external returns (uint contractId) {

        require(isRole(RoleManagementAll.Role.CPO, msg.sender),"CreateREVerification: caller is not a registered CPO");
        require(isRole(RoleManagementAll.Role.EMSP, _emsp),"CreateREVerification: given EMSP address does not have an CMSP user");
        
        //FrameworkContracts.push(Framework(_cpo, _emsp, _emsp, _cdrId, _energy, 0, 0));
        Framework memory frameworkContract;
        frameworkContract.cpo = _cpo;
        frameworkContract.emsp = _emsp;
        frameworkContract.cdrId = _cdrId;
        frameworkContract.energy = _energy;
        frameworkContract.verifiedEnergy = 0;
        frameworkContract.Status = 0; 

        
        contractId = FrameworkContracts.length;
        
        FrameworkContracts.push(frameworkContract);
        CPOIndex[_cpo].push(contractId);
        EMSPIndex[_emsp].push(contractId);
        return(contractId);
        
    }
    
    function fulfillWith(
        uint _FWId,
        uint _certId
        ) public {
            
        Framework storage current = FrameworkContracts[_FWId];
        
        require(current.cpo==msg.sender, "Only CPO is allowed to back up certificates");
        
        CertificateDefinitions.Certificate memory cert = certificateLogic.getCertificate(_certId);
        
        uint256 newVerifiedEnergy = current.verifiedEnergy + cert.energy;
        require(newVerifiedEnergy <= current.energy, "Overfulfillment: Too much energy please split Certificate before using");
        require(certificateLogic.getCertificateOwner(_certId) == msg.sender, "You have to be the Owner of the Certificate to claim it.");

        
        /*bool status;
        bytes memory result;
        (status, result) = certificateLogicAddress.delegatecall(abi.encodePacked(bytes4(keccak256("claimCertificate(uint256)")), _certId));*/
        certificateLogic.claimCertificate(_certId);
        current.verifyingCertificates.push(_certId);
        
        //Framework storage current = FrameworkContracts[_FWId];
        
        current.verifiedEnergy = newVerifiedEnergy;
        
        
        if(current.verifiedEnergy == current.energy){
             current.Status = 1;
        }
         
    }
        
    function fillInUser(
        uint _FWId,
        address _EVUser
        ) public{
        
        Framework memory current = FrameworkContracts[_FWId];
        require(msg.sender == current.emsp);
        current.evuser = _EVUser;
        
        userIndex[_EVUser].push(_FWId);
        
    }    
    
    function getAllFrameworkContracts() public view returns (Framework[] memory) {
        require(isRole(RoleManagementMin.Role.Issuer, msg.sender));
        return FrameworkContracts;
    }
    
    function getREVerificationById(uint _FWId) public view returns (Framework memory){
        require(_FWId < FrameworkContracts.length);
        return FrameworkContracts[_FWId];
    }
    
    function getREVerificationIDsByUser(address _address) public view returns (uint[] memory){
        return userIndex[_address];
    }
    
    function getREVerificationIDsByCPO(address _address) public view returns (uint[] memory){
        return CPOIndex[_address];
    }
    
    function getREVerificationIDsByEMSP(address _address) public view returns (uint[] memory){
        return EMSPIndex[_address];
    }
}