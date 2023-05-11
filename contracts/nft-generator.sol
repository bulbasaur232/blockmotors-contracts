// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@klaytn/contracts/KIP/token/KIP17/KIP17.sol";
import "@klaytn/contracts/access/Ownable.sol";
import "@klaytn/contracts/KIP/token/KIP17/extensions/KIP17URIStorage.sol";
import "@klaytn/contracts/utils/Counters.sol";
import "@klaytn/contracts/utils/Strings.sol";

contract CarNFT_Generate is KIP17, KIP17URIStorage, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;

    // 토큰이름: BlockMotors , 토큰심볼: CarNFT
    constructor() KIP17("BlockMotors", "CarNFT") {
    }

    struct CarData {                                    // _CarData[tokenId].data
        string make;            // 제조사
        string model;           // 모델
        uint16 year;            // 연식
        string licenseNum;      // 차량번호
        string registerNum;     // 등록번호
        string fuel;            // 사용연료
        uint16 cc;              // 배기량
        uint32 km;              // 주행거리
        uint32 registerDate;    // 최초등록일자
        uint32 inspectDate;     // 검사유효기간
    }

    // // 거래컨트랙트 권한 주소
    // address public tradeContractAddress;

    /*
    _CarData: tokenId => CarData                        // _CarData[tokenId]
    _CarsOwned: address => tokenId[]                    // _CarsOwned[address][n]
    */
    mapping(uint256 => CarData) private _CarData;
    mapping(address => uint256[]) private _CarsOwned;

    /*
    setCarData() : 메모리에 CarData 반환
    */
    function setCarData(
        string memory make,
        string memory model,
        uint16 year,
        string memory licenseNum,
        string memory registerNum,
        string memory fuel,
        uint16 cc,
        uint32 km,
        uint32 registerDate,
        uint32 inspectDate
    ) private pure returns (CarData memory) {
        return CarData({
            make: make,
            model: model,
            year: year,
            licenseNum: licenseNum,
            registerNum: registerNum,
            fuel: fuel,
            cc: cc,
            km: km,
            registerDate: registerDate,
            inspectDate: inspectDate
        });
    }

    /*
    generateCarNFT() : NFT를 발행하고 토큰Id 반환
    */
    function generateCarNFT(
        address to,
        string memory make,
        string memory model,
        uint16 year,
        string memory licenseNum,
        string memory registerNum,
        string memory fuel,
        uint16 cc,
        uint32 km,
        uint32 registerDate,
        uint32 inspectDate
    ) public returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _mint(to, tokenId);
        _setTokenURI(tokenId, createTokenURI(to, tokenId));
        _tokenIdCounter.increment();

        CarData memory tempCarData = setCarData(
            make,
            model,
            year,
            licenseNum,
            registerNum,
            fuel,
            cc,
            km,
            registerDate,
            inspectDate
        );

        _CarData[tokenId] = tempCarData;
        _CarsOwned[to].push(tokenId);
        
        return tokenId;
    }

    /*
    updateCarNFT() : 토큰Id의 CarData 수정
    */
    function updateCarNFT(
        uint256 tokenId,
        string memory make,
        string memory model,
        uint16 year,
        string memory licenseNum,
        string memory registerNum,
        string memory fuel,
        uint16 cc,
        uint32 km,
        uint32 registerDate,
        uint32 inspectDate
    ) public {
        require(_exists(tokenId), "Token ID does not exist");
        require(msg.sender == ownerOf(tokenId), "Only NFT owner can call this function");

        CarData memory tempCarData = setCarData(
            make,
            model,
            year,
            licenseNum,
            registerNum,
            fuel,
            cc,
            km,
            registerDate,
            inspectDate
        );

        _CarData[tokenId] = tempCarData;
    }

    /*
    getCarNFT() : 토큰Id의 CarData 반환
    */
    function getCarNFT(uint256 tokenId) public view returns (
        string memory,
        string memory,
        uint16,
        string memory,
        string memory,
        string memory,
        uint16,
        uint32,
        uint32,
        uint32
    ) {
        require(_exists(tokenId), "Token ID does not exist");
        CarData memory tempCarData = _CarData[tokenId];

        return(
            tempCarData.make,
            tempCarData.model,
            tempCarData.year,
            tempCarData.licenseNum,
            tempCarData.registerNum,
            tempCarData.fuel,
            tempCarData.cc,
            tempCarData.km,
            tempCarData.registerDate,
            tempCarData.inspectDate
        );
    }

    /*
    getOwnedTokenIds() : 사용자가 소유한 토큰Id목록 반환
    */
    function getOwnedTokenIds(address user) public view returns (uint256[] memory) {
        require(user != address(0), "User Address does not exist");
        require(_CarsOwned[user].length > 0, "User does not own any tokens");
        return _CarsOwned[user];
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
        uint256[] memory EveryTokenIds = new uint256[](index);
        for (uint256 i = 0; i < index; i++) {
            EveryTokenIds[i] = tempTokenIds[i];
        }
        return EveryTokenIds;
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
    function remapTokenId(address from, address to, uint256 tokenId) internal onlyOwner {
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
    createTokenURI() : 토큰 URI 생성
    */
    function createTokenURI(address to, uint256 tokenId) private view returns (string memory) {
        require(_exists(tokenId), "Token ID does not exist");
        return string(abi.encodePacked(to, Strings.toString(tokenId)));
    }

    /*
    tokenURI() : 토큰Id의 URI 반환 (KIP17URIStorage/Override)
    */
    function tokenURI(uint256 tokenId) public view virtual override(KIP17, KIP17URIStorage) returns (string memory) {
        require(_exists(tokenId), "Token ID does not exist");
        return KIP17URIStorage.tokenURI(tokenId);
    }

    /*
    _burn() : 토큰 소멸시 특정 로직을 추가함 (KIP17URIStorage/Override)
    */
    function _burn(uint256 tokenId) internal virtual override(KIP17, KIP17URIStorage) {
        KIP17URIStorage._burn(tokenId);
    }

}