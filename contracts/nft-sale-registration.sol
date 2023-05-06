// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./nft-generator.sol";

contract CarNFT_SaleRegistration is CarNFT{

    // 판매 등록 이벤트
    event registerSale(uint timestamp, uint tokenId, address seller);
    // 거래 완료 이벤트
    event transactionCompleted(uint timestamp, uint tokenId, address seller, address buyer); 

    uint[] internal _carsOnSale;                                // 현재 거래중인 차량 배열
    mapping(uint => Detail) internal _carDetails;              // id-세부정보 매핑
    mapping(uint => Transaction) internal _transactions;        // id-현재거래정보 매핑
    mapping(uint => Transaction[]) internal _prevTransactions;  // 이전 거래기록 매핑

    // 판매 차량 세부 정보 데이터폼
    struct Detail {
        uint registDate;                  // 등록 일자
        string userName;                  // 판매자 이름
        string userAddress;               // 판매자 주소
        string userContact;               // 판매자 연락처
        string region;                    // 판매지역
        string warranty;                  // 보증기간
        uint price;                       // 가격
        uint mileage;                     // 주행거리
        Transaction[] transferRecord;     // 이전거래내역
        Insurance insuranceRecord;        // 보험이력
        string performanceRecord;         // 성능점검기록부
    }

    // 거래 정보 데이터폼
    struct Transaction {
        uint timestamp;
        address seller;
        address buyer;
        uint price;
        Status state;
    }

    // 보험이력 데이터폼
    struct Insurance {
        uint totalLoss;      // 전손 몇회
        uint theft;          // 도난 몇회
        uint flood;          // 침수 몇회
        uint repurpose ;     // 용도변경이력
        uint changeOwner;    // 소유자변경이력
        uint changeNumber;   // 차랑변호변경이력
        uint myDamage;       // 내차 피해 횟수
        uint oppoDamage;     // 상대차 피해 횟수
        uint myAmmount;      // 내차 총 피해액
        uint oppoAmmount;    // 상대차 총 피해액
    }

    // 거래 진행 상황 enum
    enum Status {
        Registered,
        Reserved,
        Sended,
        Completed
    }

     // NFT로 발행이 된 토큰인지 체크
    modifier mintedNFT(uint _tokenId) {
        require(_exists(_tokenId), "CarNFT: Token ID does not exist");
        _;
    }

    // 판매 등록이 된 NFT인지 체크
    modifier registeredForSale(uint _tokenId) {
        require(_transactions[_tokenId].seller != address(0), "This car is not registered for sale");
        _;
    }

    // 차량 주인이 호출한 것인지 체크
    modifier onlyNFTOwner(uint _tokenId) {
        require(msg.sender == ownerOf(_tokenId), "Only NFT owner can call this function");
        _;
    }

    // 해당 함수를 호출할 단계가 맞는지 체크
    modifier correctState(uint _tokenId, Status _state) {
        require(getState(_tokenId) == _state, "Not in a correct state to call this function");
        _;
    }

    // 판매할 자동차를 등록하는 함수
    function registerCarSale(
        uint _tokenId,               // 차량 id
        string memory _userName,     // 판매자 이름
        string memory _userAddress,  // 판매자 주소
        string memory _userContact,  // 판매자 연락처
        string memory _region,       // 판매 지역
        string memory _warranty,     // 보증기간 
        uint _price,                 // 가격
        uint _mileage                // 주행거리       
    ) external mintedNFT(_tokenId) onlyNFTOwner(_tokenId){
        approve(address(this), _tokenId);
        _transactions[_tokenId].seller = msg.sender;
        _transactions[_tokenId].price = _price;
        _transactions[_tokenId].state = Status.Registered;
        _transactions[_tokenId].timestamp = block.timestamp;

        /*--------------------세부정보--------------------*/
        _carDetails[_tokenId].registDate = block.timestamp;
        _carDetails[_tokenId].userName = _userName;
        _carDetails[_tokenId].userAddress = _userAddress;
        _carDetails[_tokenId].userContact = _userContact;
        _carDetails[_tokenId].region = _region;
        _carDetails[_tokenId].warranty = _warranty;
        _carDetails[_tokenId].price = _price;
        _carDetails[_tokenId].mileage = _mileage;
        /*--------------------거래이력--------------------*/
        _carDetails[_tokenId].transferRecord = _prevTransactions[_tokenId];


        // 거래중인 차량 목록에 추가
        _carsOnSale.push(_tokenId);
        emit registerSale(block.timestamp, _tokenId, msg.sender);
    }

    // 보험이력을 등록하는 함수
    function registerInsurance(
        uint _tokenId,
        uint _totalLoss,             // 전손 몇회
        uint _theft,                 // 도난 몇회
        uint _flood,                 // 침수 몇회
        uint _repurpose,             // 용도변경이력
        uint _changeOwner,           // 소유자변경이력
        uint _changeNumber,          // 차랑변호변경이력
        uint _myDamage,              // 내차 피해 횟수
        uint _oppoDamage,            // 상대차 피해 횟수
        uint _myAmmount,             // 내차 총 피해액
        uint _oppoAmmount            // 상대차 총 피해액 
    ) external registeredForSale(_tokenId) onlyNFTOwner(_tokenId) {
        _carDetails[_tokenId].insuranceRecord = Insurance(_totalLoss, _theft, _flood, _repurpose, 
        _changeOwner, _changeNumber, _myDamage, _oppoDamage, _myAmmount, _oppoAmmount);
    }

    // 성능점검기록부 URI를 등록하는 함수
    function registerPerformance(uint _tokenId, string memory _uri) external registeredForSale(_tokenId) onlyNFTOwner(_tokenId) {
        _carDetails[_tokenId].performanceRecord = _uri;
    }

    // 판매중인 차량의 목록을 조회하는 함수
    function getCarsOnSale() public view returns (uint[] memory){
        return _carsOnSale;
    }

    // 차량의 이전 판매기록을 조회하는 함수
    function getPrevTransactions(uint _tokenId) public view mintedNFT(_tokenId) returns (Transaction[] memory) {
        return _prevTransactions[_tokenId];
    }

    // 판매할 차량의 세부정보를 조회하는 함수
    function getCarDetails(uint _tokenId) public view mintedNFT(_tokenId) registeredForSale(_tokenId) returns (Detail memory) {
        return _carDetails[_tokenId];
    }

    // 차량이 현재 거래진행중인지 체크하는 함수
    function isTrading(uint _tokenId) public view mintedNFT(_tokenId) registeredForSale(_tokenId) returns (bool) {
        return ((_transactions[_tokenId].state != Status.Registered) && (_transactions[_tokenId].state != Status.Completed));
    }

    /**
     * 현재 진행상황을 조회하는 함수 
     * 반환형은 enum이지만 실제로 반환 되는 값은 uint이므로 주의!
     */
    function getState(uint _tokenId) public view mintedNFT(_tokenId) registeredForSale(_tokenId) returns (Status) {
        return _transactions[_tokenId].state;
    }

}
