// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/klaytn/klaytn-contracts/blob/master/contracts/KIP/token/KIP17/KIP17.sol";
import "https://github.com/klaytn/klaytn-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/klaytn/klaytn-contracts/blob/master/contracts/utils/Counters.sol";
import "https://github.com/klaytn/klaytn-contracts/blob/master/contracts/utils/Strings.sol";

contract CarNFT_Generate is KIP17, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;

    // 토큰이름: BlockMotors , 토큰심볼: CarNFT
    constructor() KIP17("BlockMotors", "CarNFT") {
    }

    struct CarData {                                    // _CarData[tokenId].data
        string brand;           // 제조사
        string model;           // 모델
        string year;            // 연식
        string licenseNum;      // 차량번호
        string registerNum;     // 등록번호
        string fuel;            // 사용연료
        string cc;              // 배기량
    }

    struct CarDataWithTokenId {                         // getOwnedTokenIds()
        uint256 TokenId;        // 토큰ID
        string brand;           // 제조사
        string model;           // 모델
        string year;            // 연식
        string licenseNum;      // 차량번호
        string registerNum;     // 등록번호
        string fuel;            // 사용연료
        string cc;              // 배기량
        string URI_Register;    // 토큰URI(등록용)
        string URI_Trade;       // 토큰URI(거래용)
    }

    struct TokenURI {
        string URI_Register;    // 토큰URI(등록용)
        string URI_Trade;       // 토큰URI(거래용)
    }

    // < BlockMotors_Final >
    // 크기: 약500kb, 사이즈: 1500*900
    string private _default_Register = "https://gateway.pinata.cloud/ipfs/QmazJKCgpgzMRcPG9rvyzLHgsWHMFhRXApYquZmAEFifBa/Red_Register.png";
    string private _default_Trade = "https://gateway.pinata.cloud/ipfs/QmazJKCgpgzMRcPG9rvyzLHgsWHMFhRXApYquZmAEFifBa/Red_Trade.png";
    string private _Avante_Register = "https://gateway.pinata.cloud/ipfs/QmRkFqvK1EqSUcz3eEtPxsSqJ1sdAAsZLA5RdZTshLdjZy/Avante_Register.png";
    string private _Avante_Trade = "https://gateway.pinata.cloud/ipfs/QmRkFqvK1EqSUcz3eEtPxsSqJ1sdAAsZLA5RdZTshLdjZy/Avante_Trade.png";
    string private _Casper_Register = "https://gateway.pinata.cloud/ipfs/QmRkFqvK1EqSUcz3eEtPxsSqJ1sdAAsZLA5RdZTshLdjZy/Casper_Register.png";
    string private _Casper_Trade = "https://gateway.pinata.cloud/ipfs/QmRkFqvK1EqSUcz3eEtPxsSqJ1sdAAsZLA5RdZTshLdjZy/Casper_Trade.png";
    string private _G80_Register = "https://gateway.pinata.cloud/ipfs/QmRkFqvK1EqSUcz3eEtPxsSqJ1sdAAsZLA5RdZTshLdjZy/G80_Register.png";
    string private _G80_Trade = "https://gateway.pinata.cloud/ipfs/QmRkFqvK1EqSUcz3eEtPxsSqJ1sdAAsZLA5RdZTshLdjZy/G80_Trade.png";
    string private _Grandeur_Register = "https://gateway.pinata.cloud/ipfs/QmRkFqvK1EqSUcz3eEtPxsSqJ1sdAAsZLA5RdZTshLdjZy/Grandeur_Register.png";
    string private _Grandeur_Trade = "https://gateway.pinata.cloud/ipfs/QmRkFqvK1EqSUcz3eEtPxsSqJ1sdAAsZLA5RdZTshLdjZy/Grandeur_Trade.png";
    string private _K9_Register = "https://gateway.pinata.cloud/ipfs/QmRkFqvK1EqSUcz3eEtPxsSqJ1sdAAsZLA5RdZTshLdjZy/K9_Register.png";
    string private _K9_Trade = "https://gateway.pinata.cloud/ipfs/QmRkFqvK1EqSUcz3eEtPxsSqJ1sdAAsZLA5RdZTshLdjZy/K9_Trade.png";
    string private _Mohave_Register = "https://gateway.pinata.cloud/ipfs/QmRkFqvK1EqSUcz3eEtPxsSqJ1sdAAsZLA5RdZTshLdjZy/Mohave_Register.png";
    string private _Mohave_Trade = "https://gateway.pinata.cloud/ipfs/QmRkFqvK1EqSUcz3eEtPxsSqJ1sdAAsZLA5RdZTshLdjZy/Mohave_Trade.png";
    string private _Morning_Register = "https://gateway.pinata.cloud/ipfs/QmRkFqvK1EqSUcz3eEtPxsSqJ1sdAAsZLA5RdZTshLdjZy/Morning_Register.png";
    string private _Morning_Trade = "https://gateway.pinata.cloud/ipfs/QmRkFqvK1EqSUcz3eEtPxsSqJ1sdAAsZLA5RdZTshLdjZy/Morning_Trade.png";
    string private _Palisade_Register = "https://gateway.pinata.cloud/ipfs/QmRkFqvK1EqSUcz3eEtPxsSqJ1sdAAsZLA5RdZTshLdjZy/Palisade_Register.png";
    string private _Palisade_Trade = "https://gateway.pinata.cloud/ipfs/QmRkFqvK1EqSUcz3eEtPxsSqJ1sdAAsZLA5RdZTshLdjZy/Palisade_Trade.png";

    // // 거래컨트랙트 권한 주소
    // address public tradeContractAddress;

    /*
    _CarData: tokenId => CarData                        // _CarData[tokenId]
    _CarsOwned: address => tokenId[]                    // _CarsOwned[address][n]
    _TokenURI: KIP17Storage 추출
    */
    mapping(uint256 => CarData) private _CarData;
    mapping(address => uint256[]) private _CarsOwned;
    mapping(uint256 => TokenURI) private _TokenURI;

    /*
    setCarData() : 메모리에 CarData 반환
    */
    function setCarData(
        string memory brand,
        string memory model,
        string memory year,
        string memory licenseNum,
        string memory registerNum,
        string memory fuel,
        string memory cc
    ) private pure returns (CarData memory) {
        return CarData({
            brand: brand,
            model: model,
            year: year,
            licenseNum: licenseNum,
            registerNum: registerNum,
            fuel: fuel,
            cc: cc
        });
    }

    /*
    generateCarNFT() : NFT를 발행하고 토큰Id 반환
    */
    function generateCarNFT(
        string memory brand,
        string memory model,
        string memory year,
        string memory licenseNum,
        string memory registerNum,
        string memory fuel,
        string memory cc
    ) public returns (uint256) {
        address to = msg.sender;
        uint256 tokenId = _tokenIdCounter.current();
        _mint(to, tokenId);

        CarData memory tempCarData = setCarData(
            brand,
            model,
            year,
            licenseNum,
            registerNum,
            fuel,
            cc
        );

        _CarData[tokenId] = tempCarData;
        _CarsOwned[to].push(tokenId);
        (string memory tempTokenURI_Register, string memory tempTokenURI_Trade) = getTokenImageURI(tokenId);
        _setTokenURI(tokenId, tempTokenURI_Register, tempTokenURI_Trade);        // 차량모델 => 해당차량이미지
        _tokenIdCounter.increment();
        
        return tokenId;
    }

    /*
    updateCarNFT() : 토큰Id의 CarData 수정
    */
    function updateCarNFT(
        uint256 tokenId,
        string memory brand,
        string memory model,
        string memory year,
        string memory licenseNum,
        string memory registerNum,
        string memory fuel,
        string memory cc
    ) public {
        require(_exists(tokenId), "Token ID does not exist");
        require(msg.sender == ownerOf(tokenId), "Only NFT owner can call this function");

        CarData memory tempCarData = setCarData(
            brand,
            model,
            year,
            licenseNum,
            registerNum,
            fuel,
            cc
        );

        _CarData[tokenId] = tempCarData;
        (string memory tempTokenURI_Register, string memory tempTokenURI_Trade) = getTokenImageURI(tokenId);
        _setTokenURI(tokenId, tempTokenURI_Register, tempTokenURI_Trade);        // 차량모델 => 해당차량이미지
    }

    /*
    getCarNFT() : 토큰Id의 CarData 반환
    */
    function getCarNFT(uint256 tokenId) public view returns (
        string memory,
        string memory,
        string memory,
        string memory,
        string memory,
        string memory,
        string memory,
        string memory,
        string memory
    ) {
        require(_exists(tokenId), "Token ID does not exist");

        CarData memory tempCarData = _CarData[tokenId];
        TokenURI memory tempTokenURI = _TokenURI[tokenId];

        return(
            tempCarData.brand,
            tempCarData.model,
            tempCarData.year,
            tempCarData.licenseNum,
            tempCarData.registerNum,
            tempCarData.fuel,
            tempCarData.cc,
            tempTokenURI.URI_Register,
            tempTokenURI.URI_Trade
        );
    }

    /*
    getOwnedTokenIds() : 사용자가 소유한 토큰Id목록과 각 토큰에 대한 CarData 반환
    */
    function getOwnedTokenIds(address user) public view returns (CarDataWithTokenId[] memory) {
        require(user != address(0), "User Address does not exist");

        uint256[] memory tempTokenIds = _CarsOwned[user];
        CarDataWithTokenId[] memory ownedTokenData = new CarDataWithTokenId[](tempTokenIds.length);

        if (tempTokenIds.length == 0) {
            return new CarDataWithTokenId[](0);
        } else {
            for (uint256 i = 0; i < tempTokenIds.length; i++) {
                uint256 tokenId = tempTokenIds[i];
                (
                    string memory brand,
                    string memory model,
                    string memory year,
                    string memory licenseNum,
                    string memory registerNum,
                    string memory fuel,
                    string memory cc,
                    string memory URI_Register,
                    string memory URI_Trade
                ) = getCarNFT(tokenId);

                ownedTokenData[i] = CarDataWithTokenId({
                    TokenId: tokenId,
                    brand: brand,
                    model: model,
                    year: year,
                    licenseNum: licenseNum,
                    registerNum: registerNum,
                    fuel: fuel,
                    cc: cc,
                    URI_Register: URI_Register,
                    URI_Trade: URI_Trade
                });
            }
            return ownedTokenData;
        }
    }


    /*
    getEveryTokenIds() : 발행된 전체 토큰Id목록 반환
    */
    function getEveryTokenIds() public view returns (uint256[] memory) {
        uint256[] memory tempTokenIds = new uint256[](_tokenIdCounter.current());
        uint256 index = 0;
        for (uint256 i = 0; i < _tokenIdCounter.current(); i++) {
            uint256 tokenId = i;
            if (_exists(tokenId)) {
                tempTokenIds[index] = tokenId;
                index++;
            }
        }
        require(index > 0, "There are no tokens");

        uint256[] memory everyTokenIds = new uint256[](index);
        for (uint256 i = 0; i < index; i++) {
            everyTokenIds[i] = tempTokenIds[i];
        }
        return everyTokenIds;
    }

    /*
    deleteCarNFT() : 토큰Id의 CarData 삭제
    */
    function deleteCarNFT(uint256 tokenId) public {
        require(_exists(tokenId), "Token ID does not exist");
        require(msg.sender == ownerOf(tokenId), "Only NFT owner can call this function");
        
        delete _CarData[tokenId];
        removeTokenIdFrom(ownerOf(tokenId), tokenId);
        _transfer(ownerOf(tokenId), address(0), tokenId);
    }

    /*
    remapTokenId() : 거래완료 후 사용자가 소유한 토큰Id목록 변경
    */
    function remapTokenId(address from, address to, uint256 tokenId) internal {
        removeTokenIdFrom(from, tokenId);
        addTokenIdTo(to, tokenId);
    }

    /*
    addTokenIdTo() : 사용자가 소유한 토큰Id목록에 거래완료된 토큰Id를 추가
    */
    function addTokenIdTo(address owner, uint256 tokenId) internal {
        _CarsOwned[owner].push(tokenId);
    }

    /*
    removeTokenIdFrom() : 사용자가 소유한 토큰Id목록에 거래완료된 토큰Id를 삭제
    */
    function removeTokenIdFrom(address owner, uint256 tokenId) internal {
        uint256[] storage tempTokenIds = _CarsOwned[owner];
        for (uint256 i=0; i < _CarsOwned[owner].length; i++){
            if (tempTokenIds[i] == tokenId){
                if (i < tempTokenIds.length - 1) {
                tempTokenIds[i] = tempTokenIds[tempTokenIds.length - 1];
                }
                tempTokenIds.pop();
                break;
            }
        }
    }

    // /*
    // setTradeContractAddress() : 거래컨트랙트 권한 주소 설정
    // */
    // function setTradeContractAddress(address tradeContract) public onlyOwner {
    //     tradeContractAddress = tradeContract;
    // }

    /*
    getTokenImageURI() : 토큰 URI 생성 - 차량모델 => 해당차량이미지
    // < BlockMotors_Final >
    // 크기: 약500kb, 사이즈: 1500*900
    */
    function getTokenImageURI(uint256 tokenId) private view returns (string memory, string memory) {
        string memory model = _CarData[tokenId].model;
        // TokenURI storage tempTokenURI = _TokenURI[tokenId];
        string memory tempTokenURI_Register;
        string memory tempTokenURI_Trade;
        if (compareModel(model, "Avante")) {
            tempTokenURI_Register = _Avante_Register;
            tempTokenURI_Trade = _Avante_Trade;
        } else if (compareModel(model, "Casper")) {
            tempTokenURI_Register = _Casper_Register;
            tempTokenURI_Trade = _Casper_Trade;
        } else if (compareModel(model, "G80")) {
            tempTokenURI_Register = _G80_Register;
            tempTokenURI_Trade = _G80_Trade;
        } else if (compareModel(model, "Grandeur")) {
            tempTokenURI_Register = _Grandeur_Register;
            tempTokenURI_Trade = _Grandeur_Trade;
        } else if (compareModel(model, "K9")) {
            tempTokenURI_Register = _K9_Register;
            tempTokenURI_Trade = _K9_Trade;
        } else if (compareModel(model, "Mohave")) {
            tempTokenURI_Register = _Mohave_Register;
            tempTokenURI_Trade = _Mohave_Trade;
        } else if (compareModel(model, "Morning")) {
            tempTokenURI_Register = _Morning_Register;
            tempTokenURI_Trade = _Morning_Trade;
        } else if (compareModel(model, "Palisade")) {
            tempTokenURI_Register = _Palisade_Register;
            tempTokenURI_Trade = _Palisade_Trade;
        } else {
            tempTokenURI_Register = _default_Register;
            tempTokenURI_Trade = _default_Trade;
        }
        // return (tempTokenURI.URI_Register, tempTokenURI.URI_Trade);
        return (tempTokenURI_Register, tempTokenURI_Trade);
    }

    function compareModel(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(bytes(a)) == keccak256(bytes(b)));
    }

    /*
    KIP17Storage 직접 추출: tokenURI(), _setTokenURI(), _burn()
    */

    function tokenURI(uint256 tokenId) public view virtual override(KIP17) returns (string memory) {
        require(_exists(tokenId), "Token ID does not exist");

        TokenURI memory tempTokenURI = _TokenURI[tokenId];
        string memory base = _baseURI();
        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return tempTokenURI.URI_Register;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(tempTokenURI.URI_Register).length > 0) {
            return string(abi.encodePacked(base, tempTokenURI.URI_Register));
        }
        return super.tokenURI(tokenId);
    }

    function _setTokenURI(uint256 tokenId, string memory tempTokenURI_Register, string memory tempTokenURI_Trade) internal virtual {
        require(_exists(tokenId), "Token ID does not exist");

        TokenURI storage tempTokenURI = _TokenURI[tokenId];
        tempTokenURI.URI_Register = tempTokenURI_Register;
        tempTokenURI.URI_Trade = tempTokenURI_Trade;
    }

    function _burn(uint256 tokenId) internal virtual override {
        require(_exists(tokenId), "Token ID does not exist");
        super._burn(tokenId);
        delete _TokenURI[tokenId];
    }
}