# Renewable Energy Verification

REVerification is a PoC which attempts to provide a way to prove that an EV is charged with electricity from renewable sources.

<img src="/ContractOverview.jpg?raw=true" width="820" height="550">

The showcase here allows the comparison of the costs of different versions, with more or less data on the blockchain.

<img src="/DataStruct.png?raw=true" width="500" height="550">

The code is based on the [EnergyWeb Origin](https://github.com/energywebfoundation/origin/tree/acf41525cb9443113bd548294e040988a2418c23) project.
## How-To
The different smart contract versions are distributed in the folders "All” (name extension …all.sol), “Part” (name extension …part.sol) and “Only necessary” (name extension …min.sol). Necessary libraries are found in the folder “libs”. The paths in the contracts are adapted to the folder structure. When using Remix the paths must be adapted accordingly. 
In the following guide the filenames are always without any name extension. Depending on which version is to be used, the file must be used with the corresponding name extension.
Only the REVerification.sol in the folder “All” is fully documented since in the other versions this smart contract is not changed.

### Prerequisites
In general, the code can be compiled and then pushed to any Ethereum Virtual Machine based blockchain. Here the use of the Energy Web Volta testnet is described. As IDE Remix can be used in combination with the MetaMask browser plugin.
To get started you have two possibilities. Either use a. or b. (a. is the fastest option while b. takes some time to sync the whole blockchain):

a.	The easiest way is to use a remote RPC. Follow the guide RemoteRPC.pdf in this folder.

b.	The Evaluation was run with a local parity node. For this setup use:
1.	[Install local client](https://energyweb.atlassian.net/wiki/spaces/EWF/pages/703103027/Volta+Installing+the+Client)
2.	[Connect local node](https://energyweb.atlassian.net/wiki/spaces/EWF/pages/703135850/Volta+Connecting+Local+Node+to+MetaMask)

With either setup the remix IDE can be used: https://remix.ethereum.org/

For remix all files must be added manually. This might also require changing some paths to the libraries from the folder ‘libs’.

When all files are added make sure your MetaMask is connected to the right network. In our case Volta.

The source code should be compiled with Version 0.5.16+commit.9c3226ce https://github.com/ethereum/solc-bin/blob/gh-pages/bin/soljson-v0.5.16%2Bcommit.9c3226ce.js 

In VS Code the settings look like this:
```
"compiler": {
    "name": "solc",
    "version": "0.5.16+commit.9c3226ce
  }
```
In Remix the right compiler Version must be chosen.

![CompilerSettings](/RemixCompilerSettings.jpg?raw=true)

Make sure to have the right deployment settings and always choose the right smart contract from the dropdown menu (in this case the CertificateLogicAll):

![DeploymentSettings](/DeploymentSettings.jpg?raw=true)

### Setup
In the following guide the filenames are always without any name extension. Depending on which version is to be used, the file must be used with the corresponding name extension.
1.	Compile UserLogic.sol + deploy
2.	Compile DeviceLogic.sol + deploy
3.	Compile CertificateLogic.sol + deploy
4.	Compile REVerification.sol + deploy
5.	Initialize UserLogic by calling the ```initialize()``` procedure on the deployed smart contract
6.	Create a UserAdmin with the procedure ```createUser```, as user data make sure to use another wallet address than the one you used to deploy the contracts.
7.	Give the newly created user the UserAdmin role by calling the procedure ```setRole()```, parameters are ```role=1``` and as addresse use the same address as in step 6.
8.	Initialize the DeviceLogic with the address of the userLogic contract
9.	Initialize the CertificateLogic with the address of the DeviceLogic contract
10.	Initialize the REVerification with the address of the userlogic and the address of the devicelogic
11.	Create a Device Manager:
    * Create User with different wallet address
    * setRole role=4 address=address from a.

12.	Create Issuer
* Create User with different wallet address
* ```setRole``` ```role=32 address=address from the creted user```.

13.	DeviceManager user must create a Device:
```
Address owner = address of the Device Manager
Address Smart Meter = create new wallet address(keep it for later)
Status=0
Usage=0
```
Fill the rest with wildcards

14.	Issuer user has to setStatus() of the newly created account to active:

* Call ```setStatus``` with ```deviceId=0``` and ```status=2```

15.	Smart Meter user (wallet adress used in step 12 as smart meter)

* Call ```saveSmartMeterRead``` with parameter ```id=0 newRead= 50 hash=wildcard time= 1560989800```

16.	As Device Manager call ```requestCertificates``` with ```id=0```, leave the rest empty

17.	As Issuer call ```ApproveCertificationRequest``` with parameters ```ide=0```

### REVerification process walkthrough
1.	As Issuer call the ```setApprovedExternalContract``` with the address of the REVerification contract (this step is giving the right to the REVerification to claim certificates of anyone, rights are check in the REVerification before claiming)
2.	As CPO call the ```createREVerification``` procedure with the parameters: 
* ```Cpo = address of the caling user```, 
* ```EMSP = address of the EMSP```, 
* ```cdrID = Id of the charging process```, 
* ```energy = charged energy amount```.
3.	As CPO call the ```fulfillWith``` procedure with the parameter:
* ID of the created framework from step 2,
* ID of the certificate with which the framework should be backed up (has to exist, for example the certificate from the steps before and CPO has to be owner so a transfer might be necessary)
4.	As EMSP call the ```fillInUser``` procedure with the corresponding framework id and the user address.




