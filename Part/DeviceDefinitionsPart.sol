pragma solidity ^0.5.2;

contract DeviceDefinitionsPart {
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
        string technologyCode;
        uint lastSmartMeterReadWh;
        DeviceStatus status;
        uint refID;
    }

    struct SmartMeterRead {
        uint energy;
        uint timestamp;
    }
}