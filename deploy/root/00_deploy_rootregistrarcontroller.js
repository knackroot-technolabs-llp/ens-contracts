const { ethers } = require("hardhat");

const ZERO_HASH = '0x0000000000000000000000000000000000000000000000000000000000000000';

module.exports = async ({getNamedAccounts, deployments, network}) => {
    const {deploy} = deployments;
    const {deployer, owner} = await getNamedAccounts();

    const root = await ethers.getContract('Root');
    const stablePriceOracle = await ethers.getContract('StablePriceOracle');
    const minCommitmentAge = 5; // TODO: set it to minimum 60 seconds
    const maxCommitmentAge = 604800; // 7 days
    const rootRegistrarController = await deploy('RootRegistrarController', {
        from: deployer,
        args: [root.address, stablePriceOracle.address, minCommitmentAge, maxCommitmentAge],
        log: true
    });

    console.log(`### rootRegistrarController deployed at ${rootRegistrarController.address}`)

    await root.setController(rootRegistrarController.address, true);
    console.log(`rootRegistrarController address ${rootRegistrarController.address} is set as controller in root at ${root.address}`);


    return true;
};
module.exports.tags = ['RootRegistrarController'];
module.exports.id = "RootRegistrarController";
module.exports.dependencies = ['Root', 'StablePriceOracle'];
