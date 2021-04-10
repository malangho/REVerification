pragma solidity ^0.5.2;

contract DeviceDefinitionsMin {

    enum UsageType {
        Producing,
        Consuming
    }

    struct Device {
        address smartMeter;
        address owner;
        uint lastSmartMeterReadWh;
        uint refID;
    }

    struct SmartMeterRead {
        uint energy;
        uint timestamp;
    }
}