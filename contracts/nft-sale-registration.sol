// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./nft-generator.sol";

contract CarNFT_SaleRegistration is CarNFT{

    // 1.판매 등록 이벤트
    event registerSale(uint timestamp, uint tokenId, address seller);
    // 2. 구매 요청 이벤트
    event requestBuying(uint timestamp, uint tokenId, address buyer);
    // 3. 판매 승인 이벤트
    event approveSelling(uint timestamp, uint tokenId, address seller);
    // 4. 구매 승인 이벤트
    event approveBuying(uint timeStamp, uint tokenId, address buyer);
    // 5. 거래 완료 이벤트
    event transactionCompleted(uint timestamp, uint tokenId, address seller, address buyer); 
    // 6. 판매 취소 이벤트
    event cancelSale(uint timestamp, uint tokenId, address seller);
    // 7. 구매 취소 이벤트
    event cancelPurchase(uint timestamp, uint tokenId, address buyer);

    uint[] private _CarsOnSale;                                // 현재 거래중인 차량 배열
    mapping(uint => Detail) private _carDetails;               // id-세부정보 매핑
    mapping(uint => Transaction) private _transactions;        // id-현재거래정보 매핑
    mapping(uint => Transaction[]) private _prevTransactions;  // 이전 거래기록 매핑

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

        // 차량 등록 후 직접 가져올 데이터들
        string performanceRecord;         // 성능점검기록부
        string insuranceRecord;           // 보험이력
    }

    // 거래 정보 데이터폼
    struct Transaction {
        uint timestamp;
        address seller;
        address buyer;
        uint price;
        Status state;
    }

    // 거래 진행 상황 enum
    enum Status {
        Registered,
        Reserved,
        Sended,
        Completed,
        Canceled
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
        uint _tokenId,
        string memory _userName,
        string memory _userAddress,  
        string memory _userContact,  
        string memory _region,       
        string memory _warranty,     
        uint _price,          
        uint _mileage        
    ) public mintedNFT(_tokenId) onlyNFTOwner(_tokenId){
        // CA에게 차량 approve
        approve(address(this), _tokenId);
        _transactions[_tokenId].seller = msg.sender;
        _transactions[_tokenId].price = _price;
        _transactions[_tokenId].state = Status.Registered;
        _transactions[_tokenId].timestamp = block.timestamp;

        _carDetails[_tokenId].registDate = block.timestamp;
        _carDetails[_tokenId].userName = _userName;
        _carDetails[_tokenId].userAddress = _userAddress;
        _carDetails[_tokenId].userContact = _userContact;
        _carDetails[_tokenId].region = _region;
        _carDetails[_tokenId].warranty = _warranty;
        _carDetails[_tokenId].price = _price;
        _carDetails[_tokenId].mileage = _mileage;
        _carDetails[_tokenId].transferRecord = _prevTransactions[_tokenId];
        
        /*
        _carDetails[_tokenId].performanceRecord = 
        _carDetails[_tokenId].insuranceRecord = 
        _carDetails[_tokenId].transferRecord = 
        */

        // 거래중인 차량 목록에 추가
        _CarsOnSale.push(_tokenId);

        emit registerSale(block.timestamp, _tokenId, msg.sender);
    }

    // 차량을 판매 목록에서 제거하는 함수
    function popOnSale(uint _tokenId) internal {
        require(_CarsOnSale.length >= 0, "No cars for sale");
        require((msg.sender == _transactions[_tokenId].buyer && _transactions[_tokenId].state == Status.Completed) ||
                (msg.sender == _transactions[_tokenId].seller && _transactions[_tokenId].state == Status.Canceled), 
                "You are not authorized to remove a car from the sales list");
        uint idx = 0;
        for(uint i = 0; i < _CarsOnSale.length; i++){
            if(_CarsOnSale[i] == _tokenId){
                idx = i;
                break;
            }
        }
        require(_CarsOnSale[idx] == _tokenId, "This car is not for sale");

        _CarsOnSale[idx] = _CarsOnSale[_CarsOnSale.length - 1];
        _CarsOnSale.pop();

        // Detail과 Transation 삭제
        delete _carDetails[_tokenId];
        delete _transactions[_tokenId];
    }

    // 판매중인 차량의 목록을 조회하는 함수
    function getCarsOnSale() public view returns (uint[] memory){
        return _CarsOnSale;
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

    /*
     * 현재 진행상황을 조회하는 함수 
     * 반환형은 enum이지만 실제로 반환 되는 값은 uint이므로 주의!
     */
    function getState(uint _tokenId) public view mintedNFT(_tokenId) registeredForSale(_tokenId) returns (Status) {
        return _transactions[_tokenId].state;
    }

}
