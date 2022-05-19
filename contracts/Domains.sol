// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.14;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {StringUtils} from "./libraries/StringUtils.sol";
import {Base64} from "./libraries/Base64.sol";

error NotOwnerError(string domainname, address msgSender);
error InsufficientFundsError(uint256 price);
error AlreadyRegisteredError(string domainname);

contract Domains is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // We'll be storing our NFT images on chain as SVGs
    string svgPartOne =
        '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" xml:space="preserve" viewBox="0 0 448 448" y="0" x="0" version="1.1" enable-background="new 0 0 447.992 447.992"><defs><linearGradient id="a"><stop offset="0" stop-color="#000" stop-opacity="1"/><stop offset="1" stop-color="#000" stop-opacity="0"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" y2="403.9" x2="334.2" y1="403.9" x1="127.1" xlink:href="#a"/></defs><g color-interpolation="sRGB" color-rendering="auto" image-rendering="auto" shape-rendering="auto"><path d="M224 1068.3a176 176 0 0 0 0 352c97 0 176-78.9 176-176s-79-176-176-176z" fill="#5a3392" transform="matrix(.80216 0 0 .80216 45.7 -804.6)"/><path d="M224 1084.3a160 160 0 1 1 0 320c-88.5 0-160-71.5-160-160s71.5-160 160-160z" fill="#29a3ec" transform="matrix(.80216 0 0 .80216 45.7 -804.6)"/><path d="M224 1096.3a148 148 0 1 1 0 296c-81.9 0-148-66.2-148-148s66.1-148 148-148z" fill="#3cdef6" transform="matrix(.80216 0 0 .80216 45.7 -804.6)"/><path d="M224 1132.3a112 112 0 1 1 0 224c-62 0-112-50-112-112s50-112 112-112z" fill="#fff" transform="matrix(.80216 0 0 .80216 45.7 -804.6)"/><path d="M224 1144.3a100 100 0 1 1 .2 199.9 100 100 0 0 1-.3-199.9z" fill="#ebfeff" transform="matrix(.80216 0 0 .80216 45.7 -804.6)"/><path d="M224 1212.3c-17.6 0-32 14.4-32 32s14.4 32 32 32c17.5 0 32-14.4 32-32s-14.5-32-32-32z" fill="#5a3392" transform="matrix(.80216 0 0 .80216 45.7 -804.6)"/><path d="M224 1228.4a16 16 0 1 1-16 16c0-9 7-16 16-16z" fill="#ee746c" transform="matrix(.80216 0 0 .80216 45.7 -804.6)"/><g fill="#5a3392"><path d="M216 1020.4v144h16v-144zM216 1324.3v144h16v-144zM304 1236.3v16h144v-16zM0 1236.3v16h144v-16z" transform="matrix(.80216 0 0 .80216 45.7 -804.6)"/></g><path d="M224 1234.4a10 10 0 1 1-10 10c0-5.7 4.4-10 10-10z" fill="#fb9761" transform="matrix(.80216 0 0 .80216 45.7 -804.6)"/><g fill="#5a3392"><path d="M251.4 1119.6a8 8 0 0 0-1.3 15.7 112 112 0 0 1 82.8 82.8 8 8 0 1 0 15.6-3.7 128 128 0 0 0-94.7-94.6 8 8 0 0 0-2.4-.2zM196.2 1119.6a128 128 0 0 0-96.7 94.6 8 8 0 1 0 15.6 3.8 112 112 0 0 1 82.7-82.6 8 8 0 0 0-1.6-15.8zM340.8 1264.3a8 8 0 0 0-8 6.3 112 112 0 0 1-82.6 82.6 8 8 0 1 0 3.7 15.5 128 128 0 0 0 94.5-94.4 8 8 0 0 0-7.6-10zM106.8 1264a8 8 0 0 0-7.3 10 128 128 0 0 0 94.5 94.7 8 8 0 0 0 3.8-15.5 112 112 0 0 1-82.7-82.9 8 8 0 0 0-8.3-6.2z" transform="matrix(.80216 0 0 .80216 45.7 -804.6)"/></g></g><text y="418.2" x="230.9" style="line-height:1.25" xml:space="preserve" font-weight="700" font-size="40" font-family="Hyperspace" fill-opacity="1" fill="#fb9761" stroke="#ee6c6c" stroke-opacity="1"><tspan style="text-align:center" y="418.2" x="230.9" font-style="normal" font-variant="normal" font-weight="700" font-stretch="normal" font-family="Arial Black" text-anchor="middle" fill-opacity="1" fill="#fb9761" stroke="#ee6c6c" stroke-opacity="1">';
    string svgPartTwo = "</tspan></text></svg>";

    mapping(string => address) public domains;
    mapping(string => string) public records;

    string public tld;

    modifier onlyTokenOwner(string calldata domainname) {
        if (msg.sender != domains[domainname]) {
            revert NotOwnerError(domainname, msg.sender);
        }
        _;
    }

    constructor(string memory _tld) ERC721("Focus Name Service","FNS") {
        tld = _tld;
        console.log("%s name service deployed", _tld);
    }

    function price(string calldata name) public pure returns (uint256) {
        uint256 len = StringUtils.strlen(name);
        require(len > 0);
        if (len == 3) {
            return 5 * 10**17; // 5 MATIC = 5 000 000 000 000 000 000 (18 decimals). We're going with 0.5 Matic cause the faucets don't give a lot
        } else if (len == 4) {
            return 3 * 10**17; // To charge smaller amounts, reduce the decimals. This is 0.3
        } else {
            return 1 * 10**17;
        }
    }

    function register(string calldata name) public payable {
        if (domains[name] != address(0)) {
            revert AlreadyRegisteredError(name);
        }

        uint256 _price = price(name);
        if (msg.value < _price) {
            revert InsufficientFundsError(_price);
        }

        // Combine the name passed into the function  with the TLD
        string memory _name = string(abi.encodePacked(name, ".", tld));
        // Create the SVG (image) for the NFT with the name
        string memory finalSvg = string(
            abi.encodePacked(svgPartOne, _name, svgPartTwo)
        );
        uint256 newRecordId = _tokenIds.current();
        uint256 length = StringUtils.strlen(name);
        string memory strLen = Strings.toString(length);

        console.log(
            "Registering %s.%s on the contract with tokenID %d",
            name,
            tld,
            newRecordId
        );

        // Create the JSON metadata of our NFT. We do this by combining strings and encoding as base64
        string memory json = Base64.encode(
            abi.encodePacked(
                '{"name": "',
                _name,
                '", "description": "A domain on the Focus name service", "image": "data:image/svg+xml;base64,',
                Base64.encode(bytes(finalSvg)),
                '","length":"',
                strLen,
                '"}'
            )
        );

        string memory finalTokenUri = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        console.log(
            "\n--------------------------------------------------------"
        );
        console.log("Final tokenURI", finalTokenUri);
        console.log(
            "--------------------------------------------------------\n"
        );

        _safeMint(msg.sender, newRecordId);
        _setTokenURI(newRecordId, finalTokenUri);
        domains[name] = msg.sender;

        _tokenIds.increment();
    }

    // This will give us the domain owners' address
    function getAddress(string calldata domainname)
        public
        view
        returns (address)
    {
        return domains[domainname];
    }

    function setRecord(string calldata domainname, string calldata record)
        public
        onlyTokenOwner(domainname)
    {
        records[domainname] = record;
        console.log("%s has set the record for %s", msg.sender, domainname);
    }

    function getRecord(string calldata domainname)
        public
        view
        returns (string memory)
    {
        return records[domainname];
    }

    function withdraw() public onlyOwner(){
        payable(msg.sender).transfer(address(this).balance);
    }
}
