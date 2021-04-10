pragma solidity ^0.5.2;

import "../libs/Initializable.sol";
import "../libs/Ownable.sol";

import "./IRolesAll.sol";
import "./IUserLogicAll.sol";
import "./RoleManagementAll.sol";
import "./UserDefinitionAll.sol";

contract UserLogicAll is Initializable, RoleManagementAll, IRolesAll, IUserLogicAll {


    /// @notice mapping for addresses to users
    mapping(address => UserDefinitionAll.User) private userList;

    event UserUpdated(address _user);

    /// @notice constructor
    /// @dev it will also call the RoleManagement-constructor
    function initialize() public initializer {
        RoleManagementAll.initialize(address(this));

        // Set sender as User Admin
        UserDefinitionAll.User storage u = userList[msg.sender];
        u.roles = 2**uint(RoleManagementAll.Role.UserAdmin);
    }

    /// @notice function to deactive an use, only executable for user-admins
    /// @param _user the user that should be deactivated
    function deactivateUser(address _user)
        external
        onlyRole(RoleManagementAll.Role.UserAdmin)
    {
        require(
            !isRole(RoleManagementAll.Role.UserAdmin,_user)
            && !isRole(RoleManagementAll.Role.DeviceAdmin,_user),
            "user has an admin role at the moment"
        );

        UserDefinitionAll.User storage u = userList[_user];
        u.active = false;
    }

    /// @notice function that can be called to create a new user in the storage-contract, only executable by user-admins!
    /// @notice if the user does not exists yet it will be created, otherwise the older userdata will be overwritten
    /// @param _user address of the user
    /// @param _organization organization the user is representing
    function createUser(
        string calldata _firstname,
        string calldata _surname,
        string calldata _country,
        uint _refID,
        address _user,
        string calldata _organization
    )
        external
        onlyRole(RoleManagementAll.Role.UserAdmin)
    {
        bytes memory orgBytes = bytes(_organization);
        require(orgBytes.length > 0, "empty string");

        UserDefinitionAll.User storage u = userList[_user];
        u.firstname = _firstname;
        u.surname = _surname;
        u.country = _country;
        u.refID = _refID;
        u.organization = _organization;
        u.active = true;
    }

    /// @notice function to set / edit the rights of an user / account, only executable for Top-Admins!
    /// @param _user user that rights will change
    /// @param _rights rights encoded as bitmask
    function setRoles(address _user, uint _rights)
        external
        onlyRole(RoleManagementAll.Role.UserAdmin)
        userExists(_user)
    {
        UserDefinitionAll.User storage u = userList[_user];
        u.roles = _rights;
    }

    /// @notice function to return all the data of an user
    /// @param _user user
    /// @return returns user
    function getFullUser(address _user)
        public
        returns (
            string memory _firstname,
            string memory _surname,
            string memory _country,
            uint _refID,
            string memory _organization,
            uint _roles,
            bool _active
        )
    {
        UserDefinitionAll.User memory user = userList[_user];
        _firstname = user.firstname;
        _surname = user.surname;
        _country = user.country;
        _organization = user.organization;
        _roles = user.roles;
        _active = user.active;
        _refID = user.refID;
    }

    /// @notice function that checks if there is an user for the provided ethereum-address
    /// @param _user ethereum-address of that user
    /// @return bool if the user exists
    function doesUserExist(address _user)
        external
        view
        returns (bool)
    {
        return userList[_user].active;
    }

    /// @notice function to retrieve the rights of an user
    /// @dev if the user does not exist in the mapping it will return 0x0 thus preventing them from accidently getting any rights
    /// @param _user user someone wants to know its rights
    /// @return bitmask with the rights of the user
    function getRolesRights(address _user)
        external
        view
        returns (uint)
    {
        return userList[_user].roles;
    }

    /// @notice Updates existing user with new properties
	/// @dev will return an event with the event-Id
	/// @param _user user address
    function updateUser(
        address _user,
        string calldata _firstname,
        string calldata _surname,
        string calldata _country,
        uint _refID
    )
        external
    {
        require(msg.sender == _user, "user can only update himself");
        
        userList[_user].firstname = _firstname;
        userList[_user].surname = _surname;
        userList[_user].country = _country;
        userList[_user].refID = _refID;

        emit UserUpdated(_user);
    }
}
