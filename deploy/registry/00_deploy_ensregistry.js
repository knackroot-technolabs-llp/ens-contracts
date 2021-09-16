const { ethers } = require("hardhat");

const ZERO_HASH = '0x0000000000000000000000000000000000000000000000000000000000000000';

module.exports = async ({getNamedAccounts, deployments, network}) => {
    const {deploy} = deployments;
    const {deployer, owner} = await getNamedAccounts();

    const decentraNameController = await ethers.getContract('DecentraNameController');

    const ensRegistry = await deploy('ENSRegistry', {
        from: deployer,
        args: [decentraNameController.address],
        log: true
    });

    console.log(`### ensRegistry deployed at ${ensRegistry.address}`)

    await decentraNameController.setController(ensRegistry.address, true);
    console.log(`ensRegistry address ${ensRegistry.address} is set as controller in DecentraNameController at ${decentraNameController.address}`);

    return true;
};
module.exports.tags = ['ensRegistry'];
module.exports.id = "ensRegistry";
module.exports.dependencies = ['DecentraNameController'];
