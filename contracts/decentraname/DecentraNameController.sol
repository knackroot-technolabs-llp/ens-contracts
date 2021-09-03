pragma solidity >=0.8.4;

import "./DecentraName.sol";
import "../root/Controllable.sol";
import "./IDecentraNameController.sol";

contract DecentraNameController is IDecentraNameController, Controllable {

    DecentraName public decentraName;

    

    constructor() {
        decentraName = new DecentraName();
    }

    function ownerOf(uint256 tokenId) external virtual override view returns (address) {
        return decentraName.ownerOf(tokenId);
    }

    function isApprovedOrOwner(address spender, uint256 tokenId) external virtual override view returns (bool) {
        return decentraName.isApprovedOrOwner(spender, tokenId);
    }

    function existsToken(uint256 tokenId) external virtual override view returns (bool) {
        // TODO: it shoud not return true for expired domain
        return decentraName.existsToken(tokenId);
    }

    function burnToken(uint256 tokenId) external virtual override onlyController {
        /* TODO: signature verification has to be done before calling burn on dweb token. 
         *       Additional param may required for this method. It can be called bycontroller
         * TODO-review: should we use expiry here
         */
        decentraName.burnToken(tokenId);
    }

    // TODO-review : we do not need sign verification here because it can only be called by controller and parent owner
    function mintToken(address owner, uint256 id) external virtual override onlyController {
        decentraName.mintToken(owner, id);
    }

    function mintTokenForTLD(address owner, uint256 id) external virtual override onlyController {
        decentraName.mintToken(owner, id);
    }

    // sender should be the one who owns token id
    // this contract must be approved for sender address
    // TODO-review 
    function transferToken(address transferTo, uint256 id, uint8 v, bytes32 r, bytes32 s, address sender) external virtual override onlyController {
        // TODO-review : is it safe to use chaindId()
        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        bytes32 eip712DomainHash = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("decentraname")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        ); 

        bytes32 hashStruct = keccak256(
            abi.encode(
                keccak256("transferToken(address transferTo,uint256 id)"),
                transferTo,
                id
            )
        );

        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", eip712DomainHash, hashStruct));

        address signer = ecrecover(hash, v, r, s);
        require(signer == sender, "transferToken: invalid signature");
        require(signer != address(0), "ECDSA: invalid signature");

        decentraName.transferToken(transferTo, id);
    }

}