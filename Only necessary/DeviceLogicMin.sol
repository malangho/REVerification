pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;

import "../libs/Initializable.sol";
import "../libs/Ownable.sol";

import "./RoleManagementMin.sol";

import "./DeviceDefinitionsMin.sol";
import "./IDeviceLogicMin.sol";

/// @title Contract for storing the current logic-contracts-addresses for the certificate of origin
contract DeviceLogicMin is Initializable, RoleManagementMin, IDeviceLogicMin {

    bool private _initialized;
    address private _userLogic;

    event LogDeviceCreated(address _sender, uint indexed _deviceId);
    event LogDeviceFullyInitialized(uint indexed _deviceId);
    event LogNewMeterRead(
        uint indexed _deviceId,
        uint _oldMeterRead,
        uint _newMeterRead,
        uint _timestamp
    );

    DeviceDefinitionsMin.Device[] private allDevices;

    /// @dev mapping for device id => smart meter reads
    mapping(uint => DeviceDefinitionsMin.SmartMeterRead[]) internal _deviceSmartMeterReadsMapping;

    /// @notice constructor
    function initialize(address userLogicAddress) public initializer {
        require(userLogicAddress != address(0), "initialize: Cannot use address 0x0 as userLogicAddress.");
        _userLogic = userLogicAddress;

        RoleManagementMin.initialize(userLogicAddress);
        _initialized = true;
    }

    function userLogicAddress() public view returns (address) {
        require(_initialized == true, "userLogicAddress: The contract has not been initialized yet.");
        require(address(_userLogic) != address(0), "userLogicAddress: The device logic address is set to 0x0 address.");

        return address(_userLogic);
    }

    /**
        public functions
    */

    /// @notice gets the Device-struct as memory
    /// @param _deviceId the id of an device
    /// @return the Device-struct as memory
    function getDevice(uint _deviceId) external view returns (DeviceDefinitionsMin.Device memory device) {
        return getDeviceById(_deviceId);
    }

    /// @notice Logs meter read
    /// @param _deviceId The id belonging to an entry in the device registry
    /// @param _newMeterRead The current meter read of the device
    function saveSmartMeterRead(
        uint _deviceId,
        uint _newMeterRead,
        uint _timestamp
    )
        external
    {
        uint timestamp = _timestamp;

        require(timestamp >= 0, "a timestamp cannot be a negative number");
        require(timestamp <= block.timestamp + 60, "a timestamp cannot be higher than current block time plus 1 min");

        if (timestamp == 0) {
            timestamp = block.timestamp;
        }

        uint createdEnergy = _setSmartMeterRead(_deviceId, _newMeterRead, timestamp);

        _deviceSmartMeterReadsMapping[_deviceId].push(
            DeviceDefinitionsMin.SmartMeterRead({ energy: createdEnergy, timestamp: timestamp })
        );
    }

    /// @notice creates an device with the provided parameters
    /// @param _smartMeter smartmeter of the device
    /// @param _owner device-owner
    /// @return generated device-id
    function createDevice(
        address _smartMeter,
        address _owner,
        uint _refID
    ) external returns (uint deviceId) {
        require(isRole(RoleManagementMin.Role.DeviceManager, _owner) || isRole(RoleManagementPart.Role.CPO, _owner), "device owner has to have device manager or CPO role");
        require(
            _owner == msg.sender ||
            isRole(RoleManagementMin.Role.DeviceAdmin, msg.sender) ||
            isRole(RoleManagementMin.Role.Issuer, msg.sender),
            "only device admin and issuer can create a device for different owner"
        );
        require(
            isRole(RoleManagementMin.Role.DeviceAdmin, msg.sender) ||
            isRole(RoleManagementMin.Role.Issuer, msg.sender), "only admin and issuer can add devices with status other than submitted"
        );

        
        DeviceDefinitionsMin.Device memory _device = DeviceDefinitionsMin.Device({
            smartMeter: _smartMeter,
            owner: _owner,
            lastSmartMeterReadWh: 0,
            refID: _refID
        });

        deviceId = allDevices.length;

        allDevices.push(_device);
        emit LogDeviceCreated(msg.sender, deviceId);
    }

    function getSmartMeterReadsForDeviceByIndex(uint _deviceId, uint[] calldata _indexes) external view
        returns (DeviceDefinitionsMin.SmartMeterRead[] memory)
    {
        uint length = _indexes.length;
        DeviceDefinitionsMin.SmartMeterRead[] memory reads = new DeviceDefinitionsMin.SmartMeterRead[](length);
        DeviceDefinitionsMin.SmartMeterRead[] memory allReads = getSmartMeterReadsForDevice(_deviceId);

        for (uint i=0; i < length; i++) {
            reads[i] = allReads[_indexes[i]];
        }

        return reads;
    }

    function getSmartMeterReadsForDevice(uint _deviceId) public view
        returns (DeviceDefinitionsMin.SmartMeterRead[] memory reads)
    {
        return _deviceSmartMeterReadsMapping[_deviceId];
    }

    /// @notice Gets an device
    /// @param _deviceId The id belonging to an entry in the device registry
    /// @return Full informations of an device
    function getDeviceById(uint _deviceId) public view returns (DeviceDefinitionsMin.Device memory) {
        return allDevices[_deviceId];
    }

    /// @notice gets the owner-address of an device
    /// @param _deviceId the id of an device
    /// @return the owner of that device
    function getDeviceOwner(uint _deviceId) external view returns (address){
        return getDeviceById(_deviceId).owner;
    }

    /// @notice gets the last meterreading and its hash
    /// @param _deviceId the id of an device
    /// @return the last meterreading and its hash
    function getLastMeterReading(uint _deviceId)
        external view
        returns (uint _lastSmartMeterReadWh)
    {
        DeviceDefinitionsMin.Device memory device = getDeviceById(_deviceId);
        _lastSmartMeterReadWh = device.lastSmartMeterReadWh;
    }

    /// @notice function to get the amount of already onboarded devices
    /// @return the amount of devices already deployed
    function getDeviceListLength() public view returns (uint) {
        return allDevices.length;
    }


    /**
        Internal functions
    */

    /// @notice sets a new meterreading for an device
    /// @param _deviceId the id of an device
    /// @param _newMeterRead the new meterreading in Wh
    function _setSmartMeterRead(
        uint _deviceId,
        uint _newMeterRead,
        uint _timestamp
    ) internal returns (uint) {
        DeviceDefinitionsMin.Device storage device = allDevices[_deviceId];
        require(device.smartMeter == msg.sender, "saveSmartMeterRead: wrong sender");

        uint oldMeterRead = device.lastSmartMeterReadWh;

        /// @dev need to check if new meter read is higher then the old one
        require(_newMeterRead > oldMeterRead, "saveSmartMeterRead: meter read too low");

        device.lastSmartMeterReadWh = _newMeterRead;

        emit LogNewMeterRead(
            _deviceId,
            oldMeterRead,
            _newMeterRead,
            _timestamp
        );

        return (_newMeterRead-oldMeterRead);
    }
}
