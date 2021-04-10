pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;

import "./DeviceDefinitionsMin.sol";

contract IDeviceLogicMin {

    event LogDeviceCreated(address _sender, uint indexed _deviceId);
    event LogDeviceFullyInitialized(uint indexed _deviceId);
    event LogNewMeterRead(
        uint indexed _deviceId,
        uint _oldMeterRead,
        uint _newMeterRead,
        uint _timestamp
    );

    function userLogicAddress() public view returns (address);

    /**
        public functions
    */

    /// @notice gets the Device-struct as memory
    /// @param _deviceId the id of an device
    /// @return the Device-struct as memory
    function getDevice(uint _deviceId) external view returns (DeviceDefinitionsMin.Device memory device);


    /// @notice Logs meter read
    /// @param _deviceId The id belonging to an entry in the device registry
    /// @param _newMeterRead The current meter read of the device
    function saveSmartMeterRead(
        uint _deviceId,
        uint _newMeterRead,
        uint _timestamp) external;

    /// @notice creates an device with the provided parameters
    /// @param _smartMeter smartmeter of the device
    /// @param _owner device-owner
    /// @return generated device-id
    function createDevice(
        address _smartMeter,
        address _owner,
        uint _refID
        ) external returns (uint deviceId);

    function getSmartMeterReadsForDevice(uint _deviceId) external view
        returns (DeviceDefinitionsMin.SmartMeterRead[] memory reads);

    /// @notice Gets an device
    /// @param _deviceId The id belonging to an entry in the device registry
    /// @return Full informations of an device
    function getDeviceById(uint _deviceId) public view returns (DeviceDefinitionsMin.Device memory);

    /// @notice gets the owner-address of an device
    /// @param _deviceId the id of an device
    /// @return the owner of that device
    function getDeviceOwner(uint _deviceId) external view returns (address);

    /// @param _deviceId the id of an device
    /// @return the last meterreading
    function getLastMeterReading(uint _deviceId)
        external view
        returns (uint _lastSmartMeterReadWh);

    /// @notice function to get the amount of already onboarded devices
    /// @return the amount of devices already deployed
    function getDeviceListLength() public view returns (uint);
}
