pragma solidity >=0.8.4;

import "./DecentraName.sol";
import "../root/Controllable.sol";
import "./IDecentraNameController.sol";

// TODO: when a user owns DecentraName first time, front end must call setApprovalForAll on DecentraName contract with operater as address(this) and approved as true with owner sign

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
         * TODO: how to use expiry here
         */
        decentraName.burnToken(tokenId);
    }

    function mintToken(address owner, uint256 id) external virtual override onlyController {
        /* TODO: signature verification has to be done before calling mintToken on dweb token. 
         *       Additional param may required for this method.
         */
        decentraName.mintToken(owner, id);
    }

    function mintTokenForTLD(address owner, uint256 id) external virtual override onlyController {
        decentraName.mintToken(owner, id);
    }

    function transferToken(address to, uint256 id) external virtual override {
        /* TODO: signature verification has to be done before calling transferToken on dweb token. 
         *       Additional param may required for this method. can only be done by owner. signature verification will work here
         */
        decentraName.transferToken(to, id);
    }


}