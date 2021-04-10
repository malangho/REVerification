pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;

import "../libs/Initializable.sol";

import "./CertificateDefinitions.sol";
import "./ICertificateLogic.sol";
import "./RoleManagementAll.sol";

contract REVerification is Initializable, RoleManagementAll{
    
    
    bool private _initialized;
    address private userLogicAddress;
    address certificateLogicAddress;
    ICertificateLogic private certificateLogic;
    
    enum Status {
        Open,
        Verified
    }
    
    // Framework in which the necessary data is stored to verify the use of RE
    struct Framework {
        address cpo;
        address emsp;
        address evuser;
        string cdrId; //combination of CPO and cdrId identify the charging process for which the verification should be done
        uint16 energy; //charged amount of energy
        uint256[] verifyingCertificates; //List of certificates that were claimed in order to back up the claim of having RE used in the charging process by the CPO and the specific cdrId
        uint256 verifiedEnergy; //backed up amount of energy
        uint8 Status;
    }
    
    // Array in which all framework structs are stored
    Framework[] private FrameworkContracts;
    // Indeces to get the list of frameworks associated with a specific address
    mapping(address => uint[]) private userIndex;
    mapping(address => uint[]) private CPOIndex;
    mapping(address => uint[]) private EMSPIndex;
    
    function initialize(address userlogic, address _certificateLogic) public initializer {
        RoleManagementAll.initialize(userlogic);
        userLogicAddress = userlogic;
        certificateLogicAddress = _certificateLogic;
        certificateLogic = ICertificateLogic(_certificateLogic);
        _initialized=true;
    }
    
    // Create a verifying framework with all necessary information to later proof the use of RE
    // Returns the ID of the created framework
    function createREVerification(
        address _cpo,
        address _emsp,
        string calldata _cdrId,
        uint16 _energy
    ) external returns (uint contractId) {

        //check if caller is a CPO and if the given EMSP Address resembles to a user with EMSP role
        require(isRole(RoleManagementAll.Role.CPO, msg.sender),"CreateREVerification: caller is not a registered CPO"); //can also be changed to be independent of the caller by just checking the given param _cpo
        require(isRole(RoleManagementAll.Role.EMSP, _emsp),"CreateREVerification: given EMSP address does not have an CMSP user");
        
        //initialize the specific framework with the given parameters
        Framework memory frameworkContract;
        frameworkContract.cpo = _cpo;
        frameworkContract.emsp = _emsp;
        frameworkContract.cdrId = _cdrId;
        frameworkContract.energy = _energy;
        frameworkContract.verifiedEnergy = 0;
        frameworkContract.Status = 0; 

        //unique ID of the framework to tell the frameworks apart
        contractId = FrameworkContracts.length;

        //add framework to the list of all frameworks
        FrameworkContracts.push(frameworkContract);

        //Maintenance of the index
        CPOIndex[_cpo].push(contractId);
        EMSPIndex[_emsp].push(contractId);

        return(contractId);
        
    }
    
    // Back up a created framework (_FWId) with the certificates (_certId) given as parameters
    function fulfillWith(
        uint _FWId,
        uint _certId
        ) public {
        
        //get the framework to be edited    
        Framework storage current = FrameworkContracts[_FWId];
        
        //check if sender is cpo of the given framework
        require(current.cpo==msg.sender, "Only CPO is allowed to back up certificates");

        //retrieve certificate data
        CertificateDefinitions.Certificate memory cert = certificateLogic.getCertificate(_certId);

        //check if certificate is overfulfilling the framework if that is the case the transaction is reverted, only certificates matching the remaining energy or less are accepted, certificate has to be split up before
        uint256 newVerifiedEnergy = current.verifiedEnergy + cert.energy;
        require(newVerifiedEnergy <= current.energy, "Overfulfillment: Too much energy please split Certificate before using");

        //check if sender is owner of certificate
        require(certificateLogic.getCertificateOwner(_certId) == msg.sender, "You have to be the Owner of the Certificate to claim it.");

        
        /*bool status;
        bytes memory result;
        (status, result) = certificateLogicAddress.delegatecall(abi.encodePacked(bytes4(keccak256("claimCertificate(uint256)")), _certId));*/

        //claim certificate: only possible if this contract instance is approved external contract in CertificateLogic since claim is executed in the context of the REVerification contract
        certificateLogic.claimCertificate(_certId);
        //refresh list of certificates used to back up this REVerifiaton framework
        current.verifyingCertificates.push(_certId);
        
        //Framework storage current = FrameworkContracts[_FWId];
        
        current.verifiedEnergy = newVerifiedEnergy;
        
        //if the verified energy amount is matching the targeted energy the framework achieves the status 'verified'
        if(current.verifiedEnergy == current.energy){
             current.Status = 1;
        }
         
    }
        
    function fillInUser(
        uint _FWId,
        address _EVUser
        ) public{
        
        //get the framework to be edited
        Framework memory current = FrameworkContracts[_FWId];

        //check if the sender is authorized, means is according to the framework contract the emsp
        require(msg.sender == current.emsp);
        //set the EV User
        current.evuser = _EVUser;
        
        //maintain the Index
        userIndex[_EVUser].push(_FWId);
        
    }    
    

    //retrieve all existing framework contracts, expensive procedure, rstricted to the Issuer only
    function getAllFrameworkContracts() public view returns (Framework[] memory) {
        require(isRole(RoleManagementAll.Role.Issuer, msg.sender));
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