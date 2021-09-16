pragma solidity >=0.8.4;

import "./DecentraName.sol";
import "../root/Controllable.sol";
import "./IDecentraNameController.sol";

contract DecentraNameController is IDecentraNameController, Controllable {

    DecentraName public decentraName;

    constructor() {
        decentraName = new DecentraName();
    }

    // pure or view methods
    function ownerOf(uint256 tokenId) external virtual override view returns (address) {
        return decentraName.ownerOf(tokenId);
    }

    function isApprovedOrOwner(address spender, uint256 tokenId) external virtual override view returns (bool) {
        return decentraName.isApprovedOrOwner(spender, tokenId);
    }

    // This method only returns if token alredy mint or not. to know if token is valid and not expired use root.available
    function existsToken(uint256 tokenId) external virtual override view returns (bool) {
        return decentraName.existsToken(tokenId);
    }

    // modifier protected methods
    function burnToken(uint256 tokenId) external virtual override onlyController {
        /*
         * TODO: should we use expiry here
         */
        decentraName.burnToken(tokenId);
    }

    function mintToken(address owner, uint256 id) external virtual override onlyController {
        decentraName.mintToken(owner, id);
    }

    // sender should be the one who owns token id
    // this contract must be approved for sender address
    function transferToken(address transferTo, uint256 id, uint8 v, bytes32 r, bytes32 s, address sender) external virtual override onlyController {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        // TODO: change transferToken to TransferToken and add salt in domain separator
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