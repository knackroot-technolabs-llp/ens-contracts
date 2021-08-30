const { ethers } = require("hardhat");

const ZERO_HASH = '0x0000000000000000000000000000000000000000000000000000000000000000';

module.exports = async ({getNamedAccounts, deployments, network}) => {
    const {deploy} = deployments;
    const {deployer, owner} = await getNamedAccounts();

    const ensRegistry = await ethers.getContract('ENSRegistry');
    const decentraNameController = await ethers.getContract('DecentraNameController');

    const root = await deploy('Root', {
        from: deployer,
        args: [ensRegistry.address, decentraNameController.address],
        log: true
    });

    console.log(`### root deployed at ${root.address}`)

    await decentraNameController.setController(root.address, true);
    console.log(`root address ${root.address} is set as controller in DecentraNameController at ${decentraNameController.address}`);

    const rootContract = await ethers.getContract('Root');
    await rootContract.setRootDomainOwner();
    console.log(`set root address ${root.address} as owner of root domain(0x0)`);

    return true;
};
module.exports.tags = ['root'];
module.exports.id = "root";
module.exports.dependencies = ['ENSRegistry', 'DecentraNameController'];
