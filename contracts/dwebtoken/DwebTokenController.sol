pragma solidity >=0.8.4;

import "./DwebToken.sol";
import "../root/Controllable.sol";

// TODO: when a user owns dwebtoken first time, front end must call setApprovalForAll on dwebToken contract with operater as address(this) and approved as true with owner sign

contract DwebTokenController is Controllable {

    DwebToken public dwebToken;

    constructor() {
        dwebToken = new DwebToken();
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        return dwebToken.ownerOf(tokenId);
    }

    function isApprovedOrOwner(address spender, uint256 tokenId) public view returns (bool) {
        return dwebToken.isApprovedOrOwner(spender, tokenId);
    }

    function existsToken(uint256 tokenId) public view returns (bool) {
        // TODO: it shoud not return true for expired domain
        return dwebToken.existsToken(tokenId);
    }

    function burnToken(uint256 tokenId) public onlyController {
        /* TODO: signature verification has to be done before calling burn on dweb token. 
         *       Additional param may required for this method. It can be called bycontroller
         * TODO: how to use expiry here
         */
        dwebToken.burnToken(tokenId);
    }

    function mintToken(address owner, uint256 id) public {
        /* TODO: signature verification has to be done before calling mintToken on dweb token. 
         *       Additional param may required for this method.
         */
        dwebToken.mintToken(owner, id);
    }

    function mintTokenForTLD(address owner, uint256 id) public onlyController {
        dwebToken.mintToken(owner, id);
    }

    function transferToken(address to, uint256 id) public {
        /* TODO: signature verification has to be done before calling transferToken on dweb token. 
         *       Additional param may required for this method. can only be done by owner. signature verification will work here
         */
        dwebToken.transferToken(to, id);
    }


}