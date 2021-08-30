const ethers = require("ethers");
const namehash = require('eth-ens-namehash');

const decentraNameControllerABI = require('../build/contracts/DecentraNameController.json');
const dummyOracleABI = require('../build/contracts/DummyOracle.json');
const stablePriceOracleABI = require('../build/contracts/StablePriceOracle.json');
const ensRegistryABI = require('../build/contracts/ENSRegistry.json');
const rootABI = require('../build/contracts/Root.json');
const rootRegistrarControllerABI = require('../build/contracts/RootRegistrarController.json');

const decentraNameABI = require('../build/contracts/DecentraName.json');


const decentraNameAddr = '0xF93a577FC33F523E2b22f8684E4b25b44d78BA88';

const decentraNameControllerAddr = '0x8855EA28Be55Bdf1FdB996eb9b8108f115039c9c';
const dummyOracleAddr = '0xDAf628947A8C8848f238707dA923458E41FE9457';
const stablePriceOracleAddr = '0x0d6e146AAe33fd44826C28E7d8FcC7E8454fF1c1';
const ensRegistryAddr = '0x84480E619f56163302FC000be098f2eeAAeBE7e8';
const rootAddr = '0x5610c40f26041E5a31AD93D1F8D4d3e31F12f866';
const rootRegistrarControllerAddr = '0xC8D17ad3236e2ECc811877507a1Af8317Cee737a';




const RPCUrl = 'http://127.0.0.1:7545';


const acc2 = "0x5CC0c5BB619C34DE8Fa6C7613f6388A41a1a488d"
const acc2pri = 'd49387b82b1fcaa1741f3cd950cefd1d2e32ffb7d8cfce104720db9c9e76f3c4';

const provider = new ethers.providers.JsonRpcProvider(RPCUrl);
const wallet = new ethers.Wallet(acc2pri, provider);

const decentraNameControllerContract = new ethers.Contract(decentraNameControllerAddr, JSON.parse(JSON.stringify(decentraNameControllerABI)), wallet);
const dummyOracleContract = new ethers.Contract(dummyOracleAddr, JSON.parse(JSON.stringify(dummyOracleABI)), wallet);
const stablePriceOracleContract = new ethers.Contract(stablePriceOracleAddr, JSON.parse(JSON.stringify(stablePriceOracleABI)), wallet);
const ensRegistryContract = new ethers.Contract(ensRegistryAddr, JSON.parse(JSON.stringify(ensRegistryABI)), wallet);
const rootContract = new ethers.Contract(rootAddr, JSON.parse(JSON.stringify(rootABI)), wallet);
const rootRegistrarControllerContract = new ethers.Contract(rootRegistrarControllerAddr, JSON.parse(JSON.stringify(rootRegistrarControllerABI)), wallet);
var decentraNameContract = new ethers.Contract(decentraNameAddr, JSON.parse(JSON.stringify(decentraNameABI)), wallet);


async function makeCommitment(name, owner, secret='') {
    
    const commitment = await rootRegistrarControllerContract.makeCommitment(name, owner, secret);
    await rootRegistrarControllerContract.commit(commitment);
}

async function commit(name, owner, secret) {
    await makeCommitment(name, owner, secret);
}

async function register(domainName, owner, duration, secret) {
    await commit(domainName, owner, secret);

    console.log('Waiting for 7 sec');
    await new Promise(r => setTimeout(r, 7000));

    // 1 min wait
    let price = await rootRegistrarControllerContract.rentPrice(domainName, duration);
    price = price.mul(110).div(100);

    console.log(`calculated price: ${ethers.utils.formatUnits(price, 'ether')}`);
    const gasLimit = ethers.utils.parseUnits('2000000', 'wei');
    await rootRegistrarControllerContract.register(domainName, owner, duration, secret, {value: price, gasLimit});

}

async function main () {    
    

    //let wallet1 = new ethers.Wallet(acc1);
    // let signedMsg = await wallet.signMessage(binaryData)

    // let wallet = new ethers.Wallet(privateKey, provider);
    // let tx = wallet.sendTransaction(tx);

    // console.log(`Is domain exist: ${await decentraNameContract.existsToken(namehash.hash('abc'))}`);
    
    // Register domain
    await register('abe', acc2, 31556926, '0x9ffc3ebd3f201e8eecd71b2833365ad37a2b6a74bad78f666724f9082fdd8a73');

    // console.log(`is domain available? ${await rootRegistrarControllerContract.available('abd')}`);
    

  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });