const ethers = require("ethers");
const namehash = require('eth-ens-namehash');
const sha3 = require('js-sha3').keccak_256

const decentraNameControllerABI = require('../build/contracts/DecentraNameController.json');
const dummyOracleABI = require('../build/contracts/DummyOracle.json');
const stablePriceOracleABI = require('../build/contracts/StablePriceOracle.json');
const ensRegistryABI = require('../build/contracts/ENSRegistry.json');
const rootABI = require('../build/contracts/Root.json');
const rootRegistrarControllerABI = require('../build/contracts/RootRegistrarController.json');

const decentraNameABI = require('../build/contracts/DecentraName.json');


const decentraNameAddr = '0xaD95C4A37DAF2a51d31251eC8e82C48F602Ae26D';

const decentraNameControllerAddr = '0x53213ecAB90Bc6e32D83E405910aB27F23635fEE';
const dummyOracleAddr = '0xac98ae75daa00ddc1996ad3a87135c19c346ce81';
const stablePriceOracleAddr = '0x86E8f9363e799D8CCF21c92dc2cdaBAe399134F3';
const ensRegistryAddr = '0x61E3Ee6374AE0d4c04168d666a5dAC7bCFBd57f0';
const rootAddr = '0x39A614eDF20f573D965A1d058545CB4074E556C4';
const rootRegistrarControllerAddr = '0x1C3F7745244E67619c27175cb21C58d195656771';




// const RPCUrl = 'http://127.0.0.1:7545';
const RPCUrl = 'https://rinkeby.infura.io/v3/a179f100768a423fa0eebdcbc984b61b';


const acc2 = "0x71504cbCD9E376C2f6CF791C91349B45c387Fa88"
const acc2pri = "fd310b1dacfad5ccdb8274c69cefde7b11fa9e9e97caec4edf6d6b2bc51ce414";
const acc3 = "0x3b242112099A4abf3Dc8aa79F669cb86FAfDCc27";
const acc3pri = "89c66c890ba3c20eac0177c2a90b8dd34b634254681cbd99ab02b51e0deefab7";
const acc4 = "0xf91eF62a17E9A3669c20088FB74E918Ecb01DAB1";
// const acc4pri = "39d9f533e3045cdc3a0ac8d3a117efa9b35a8b9ae9634bba4d798cada7fc400f";


const provider = new ethers.providers.JsonRpcProvider(RPCUrl);
const wallet2 = new ethers.Wallet(acc2pri, provider);
const wallet3 = new ethers.Wallet(acc3pri, provider);

const decentraNameControllerContract = new ethers.Contract(decentraNameControllerAddr, JSON.parse(JSON.stringify(decentraNameControllerABI)), provider);
const dummyOracleContract = new ethers.Contract(dummyOracleAddr, JSON.parse(JSON.stringify(dummyOracleABI)), provider);
const stablePriceOracleContract = new ethers.Contract(stablePriceOracleAddr, JSON.parse(JSON.stringify(stablePriceOracleABI)), provider);
const ensRegistryContract = new ethers.Contract(ensRegistryAddr, JSON.parse(JSON.stringify(ensRegistryABI)), provider);
const rootContract = new ethers.Contract(rootAddr, JSON.parse(JSON.stringify(rootABI)), provider);
const rootRegistrarControllerContract = new ethers.Contract(rootRegistrarControllerAddr, JSON.parse(JSON.stringify(rootRegistrarControllerABI)), provider);
var decentraNameContract = new ethers.Contract(decentraNameAddr, JSON.parse(JSON.stringify(decentraNameABI)), provider);


async function makeCommitment(name, owner, secret='') {
    
    const commitment = await rootRegistrarControllerContract.connect(wallet2).makeCommitment(name, owner, secret);
    await rootRegistrarControllerContract.connect(wallet2).commit(commitment);
}

async function commit(name, owner, secret) {
    await makeCommitment(name, owner, secret);
}

async function register(domainName, owner, duration, secret) {
    await commit(domainName, owner, secret);

    console.log('Waiting for 7 sec');
    await new Promise(r => setTimeout(r, 7000));

    // 1 min wait
    let price = await rootRegistrarControllerContract.connect(wallet2).rentPrice(domainName, duration);
    price = price.mul(110).div(100);

    console.log(`calculated price: ${ethers.utils.formatUnits(price, 'ether')}`);
    const gasLimit = ethers.utils.parseUnits('2000000', 'wei');
    await rootRegistrarControllerContract.connect(wallet2).register(domainName, owner, duration, secret, {value: price, gasLimit});
}

async function getOwner(domainName) {
    const label = namehash.hash(domainName);
    return await decentraNameControllerContract.connect(wallet2).ownerOf(label);
}

async function createSubDomain(parent, label, owner) {
    const subnode = await ensRegistryContract.connect(wallet2).createSubnode(namehash.hash(parent), '0x' + sha3(namehash.normalize(label)), owner);
    console.log(`subnode created ${subnode}`);
}

async function transferDomain(node, owner) {
    await decentraNameContract.connect(wallet2).setApprovalForAll(decentraNameControllerAddr, true);
    await ensRegistryContract.connect(wallet2).setOwner(namehash.hash(node), owner);
}

async function transferSubDomain(parent, label, owner) {
    await decentraNameContract.connect(wallet3).setApprovalForAll(decentraNameControllerAddr, true);
    await ensRegistryContract.connect(wallet2).setSubnodeOwner(namehash.hash(parent), '0x' + sha3(namehash.normalize(label)), owner);
}

async function main () {
    

    //let wallet1 = new ethers.Wallet(acc1);
    // let signedMsg = await wallet.signMessage(binaryData)
    // contract.connect(wallet);

    // let wallet = new ethers.Wallet(privateKey, provider);
    // let tx = wallet.sendTransaction(tx);

    // console.log(`Is domain exist: ${await decentraNameContract.existsToken(namehash.hash('abc'))}`);
    
    // Register domain
    await register('abc', acc2, 31556926, '0x9ffc3ebd3f201e8eecd71b2833365ad37a2b6a74bad78f666724f9082fdd8a10');

    // const subdomain = 'acc9'
    // // create subdomain acc2.abc
    // await createSubDomain('abc', subdomain, acc2);
    // console.log(`Owner is ${await getOwner(`${subdomain}.abc`)}`);

    // // Transfer domain acc2.abc
    // await transferDomain(`${subdomain}.abc`, acc3);

    // console.log(`Owner is ${await getOwner(`${subdomain}.abc`)}`);

    // // Transfer subdomain
    // await transferSubDomain('abc', subdomain, acc4);
    // console.log(`Owner is ${await getOwner(`${subdomain}.abc`)}`);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });