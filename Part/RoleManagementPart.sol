pragma solidity ^0.5.2;

import "../libs/Initializable.sol";

import "./IRolesPart.sol";
import "./IUserLogicPart.sol";

/// @notice contract for managing the rights and roles
contract RoleManagementPart is Initializable {

    /// @notice all possible available roles
    /*
    no role:        0x0...------0 = 0
    UserAdmin:      0x0...------1 = 1
    DeviceAdmin:     0x0...-----1- = 2
    DeviceManager:   0x0...----1-- = 4
    Trader:         0x0...---1--- = 8
    Matcher:        0x0...--1---- = 16
    Issuer:         0x0...-1----- = 32
    Listener:         0x0...1------ = 64
    CPO:           0x0...1------ = 128
    EMSP:           0x0...1------ = 256
    */
    enum Role {
        UserAdmin,
        DeviceAdmin,
        DeviceManager,
        Trader,
        Matcher,
        Issuer,
        Listener,
        CPO,
        EMSP
    }

    ///@param contract-lookup for users
    IUserLogicPart public userLogicContract;

    /// @notice modifier for checking if an user is allowed to execute the intended action
    /// @param _role one of the roles of the enum Role
    modifier onlyRole(RoleManagementPart.Role _role) {
        require(isRole(_role, msg.sender), "user does not have the required role");
        _;
    }

    /// @notice modifier for checking that only a certain account can do an action
    /// @param _accountAddress the account that should be allowed to do that action
    modifier onlyAccount(address _accountAddress) {
        require(msg.sender == _accountAddress, "account is not accountAddress");
        _;
    }

    /// @notice modifier that checks, whether an user exists
    /// @param _user the user that has to be checked for existence
    modifier userExists(address _user){
        require(IRolesPart(address(userLogicContract)).doesUserExist(_user), "User does not exist");
        _;
    }

    /// @notice modifier that checks, whether a user has a certain role
    /// @param _role one of the roles of the enum Role
    /// @param _user the address of the user to be checked for the role
    modifier userHasRole(RoleManagementPart.Role _role, address _user){
        require (isRole(_role, _user), "user does not have the required role");
        _;
    }

    /// @notice constructor
    /// @param _userLogicContract contract-lookup instance
    function initialize(address _userLogicContract) public initializer {
        userLogicContract = IUserLogicPart(_userLogicContract);
    }

    /// @notice function for comparing the role and the needed rights of an user
    /// @param _role role of a user
    /// @param _caller the user trying to call the action
    /// @return whether the user has the corresponding rights for the intended action
    function isRole(RoleManagementPart.Role _role, address _caller) public view returns (bool) {
        /// @dev reading the rights for the user from the userDB-contract
        uint rights = IRolesPart(address(userLogicContract)).getRolesRights(_caller);
        /// @dev converting the used enum to the corresponding bitmask
        uint role = uint(2) ** uint(_role);
        /// @dev comparing rights and roles, if the result is not 0 the user has the right (bitwise comparison)
        /// we also don't have to check for a potential overflow here, because the used enum will prevent using roles that do not exist
        return (rights & role != 0);
    }
}
