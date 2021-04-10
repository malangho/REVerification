pragma solidity ^0.5.2;

contract DeviceDefinitionsAll {
    enum DeviceStatus {
        Submitted,
        Denied,
        Active
    }

    enum UsageType {
        Producing,
        Consuming
    }

    struct Device {
        UsageType usageType;
        address smartMeter;
        address owner;
        string ETRS89position;
        string technologyCode;
        string fuelCode;
        uint lastSmartMeterReadWh;
        DeviceStatus status;
        uint refID;
    }

    struct SmartMeterRead {
        uint energy;
        uint timestamp;
    }
}