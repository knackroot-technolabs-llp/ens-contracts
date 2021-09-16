const { ethers } = require("hardhat");

const ZERO_HASH = '0x0000000000000000000000000000000000000000000000000000000000000000';

module.exports = async ({getNamedAccounts, deployments, network}) => {
    const {deploy} = deployments;
    const {deployer, owner} = await getNamedAccounts();

    const decentraNameController = await deploy('DecentraNameController', {
        from: deployer,
        args: [],
        log: true
    });

    const contract = await ethers.getContract('DecentraNameController');
    const decentraName = await contract.decentraName();
    console.log(`### decentra contract ${decentraName}`)
    console.log(`### DecentraNameController deployed at ${decentraNameController.address}`)

    return true;
};
module.exports.tags = ['DecentraNameController'];
module.exports.id = "DecentraNameController";
