pragma solidity >=0.8.4;

import "./DecentraName.sol";
import "../root/Controllable.sol";
import "./IDecentraNameController.sol";

// TODO: when a user owns DecentraName first time, front end must call setApprovalForAll on DecentraName contract with operater as address(this) and approved as true with owner sign

contract DecentraNameController is IDecentraNameController, Controllable {

    DecentraName public decentraName;

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
         * TODO: how to use expiry here
         */
        decentraName.burnToken(tokenId);
    }

    // TODO-review : we do not need sign verification here because it can only be called by controller and parent owner
    function mintToken(address owner, uint256 id) external virtual override onlyController {
        /* TODO: signature verification has to be done before calling mintToken on dweb token. 
         *       Additional param may required for this method.
         */
        decentraName.mintToken(owner, id);
    }

    function mintTokenForTLD(address owner, uint256 id) external virtual override onlyController {
        decentraName.mintToken(owner, id);
    }

    function transferToken(address transferTo, uint256 id) external virtual override {
        /* TODO: signature verification has to be done before calling transferToken on dweb token. 
         *       Additional param may required for this method. can only be done by owner. signature verification will work here
         */
        bytes32 hashStruct = keccak256(
            abi.encode(
                keccak256("transferToken(address transferTo,uint256 id)"),
                transferTo,
                id
            )
        );


        decentraName.transferToken(to, id);
    }

    // function verifySignature(address sender, address transferTo)

    function splitSignature(bytes memory sig) internal pure returns (uint8, bytes32, bytes32) {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }


}