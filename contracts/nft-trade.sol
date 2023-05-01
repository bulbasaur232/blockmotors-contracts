// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./nft-generator.sol";

contract CarNFT_Trade is CarNFT{

    // 1. 판매 등록 이벤트
    event registerSale(uint timestamp, uint tokenId, address seller);
    // 2. 판매 취소 이벤트
    event cancelSale(uint timestamp, uint tokenId, address seller);
    // 3. 구매 요청 이벤트
    event requestBuying(uint timestamp, uint tokenId, address buyer);
    // 4. 판매 승인 이벤트
    event approveBuying(uint timestamp, uint tokenId, address seller);
    // 5. 거래 완료 이벤트
    event transactionCompleted(uint timestamp, uint tokenId, address seller, address buyer);
    // 6. 구매승인기한 초과로 거래 취소 이벤트
    event approvalOverdue(uint timestamp, uint tokenId, address buyer);
    

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

    // 거래 진행 상황
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


    // 자동차의 이전 판매기록을 조회하는 함수
    function getPrevTransactions(uint _tokenId) public view mintedNFT(_tokenId) returns (Transaction[] memory) {
        return _prevTransactions[_tokenId];
    }

    // 판매할 차량의 세부정보를 조회하는 함수
    function getCarDetails(uint _tokenId) public view mintedNFT(_tokenId) registeredForSale(_tokenId) returns (Detail memory) {
        return _carDetails[_tokenId];
    }

    // 자동차가 현재 거래진행중인지 체크하는 함수
    function isTrading(uint _tokenId) public view mintedNFT(_tokenId) registeredForSale(_tokenId) returns (bool) {
        return (_transactions[_tokenId].state != Status.Registered);
    }

    /*
     * 현재 진행상황을 조회하는 함수 
     * 반환형은 enum이지만 실제로 반환 되는 값은 uint이므로 주의!
     */
    function getState(uint _tokenId) public view mintedNFT(_tokenId) registeredForSale(_tokenId) returns (Status) {
        return _transactions[_tokenId].state;
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
    ) public onlyNFTOwner(_tokenId) mintedNFT(_tokenId) {

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

        emit registerSale(block.timestamp, _tokenId, msg.sender);
    }

    /*
     * 판매를 취소하는 함수
     * sellCar()를 호출해서 CA로 전송했으면 취소 불가!!
     */
    function cancelCarSale(uint _tokenId) public onlyNFTOwner(_tokenId) registeredForSale(_tokenId) {

        // CA의 NFT approve 취소 
        _approve(address(0), _tokenId);
        // 등록했던 Detail과 Transaction 삭제
        delete _carDetails[_tokenId];
        delete _transactions[_tokenId];

        emit cancelSale(block.timestamp, _tokenId, msg.sender);
    }

    /*
     * 구매를 취소하는 함수
     * 구매자가 취소 or 구매 승인 기한 지났을 경우 호출
     */
    function cancelCarPurchase(uint _tokenId) public {
        require(isTrading(_tokenId), "This car is not trading.");
        require(msg.sender == _transactions[_tokenId].buyer, "The caller is not the buyer.");

        _transactions[_tokenId].timestamp = _carDetails[_tokenId].registDate;
        _transactions[_tokenId].buyer = address(0);
        _transactions[_tokenId].state = Status.Registered;
    }

    // 구매자가 클레이를 지불하여 구매 요청을 보내는 함수
    function reserveCar(uint _tokenId) public payable registeredForSale(_tokenId) correctState(_tokenId, Status.Registered) {
        // 이미 거래중이면 revert
        require(isTrading(_tokenId) , "This car is currently being traded");
        // 보낸 클레이가 가격보다 적으면 revert
        require(msg.value >= _carDetails[_tokenId].price, "Not enough KLAY to buy a car");
        (bool success, ) = payable(address(this)).call{value:msg.value}("");
        require(success, "Failed to send KLAY to Contract");
    
        _transactions[_tokenId].buyer = msg.sender;
        _transactions[_tokenId].state = Status.Reserved;
        _transactions[_tokenId].timestamp = block.timestamp;


        emit requestBuying(block.timestamp, _tokenId, msg.sender);
    }

    // 판매자가 NFT를 CA로 전송하여 판매 승인하는 함수
    function sendCar(uint _tokenId) public onlyNFTOwner(_tokenId) registeredForSale(_tokenId) correctState(_tokenId, Status.Reserved) {
        // nft를 판매자가 ca에게 전송
        safeTransferFrom(msg.sender, address(this), _tokenId);
        _transactions[_tokenId].state = Status.Sended;
        _transactions[_tokenId].timestamp = block.timestamp;

        
        emit approveBuying(block.timestamp, _tokenId, msg.sender);
    }

    // 구매자가 최종 구매 승인하는 함수
    function confirmBuying(uint _tokenId) public registeredForSale(_tokenId) correctState(_tokenId, Status.Sended) {
        // msg.sender가 구매자가 아니면 revert 
        require(msg.sender == _transactions[_tokenId].buyer, "Caller is not the buyer of this car");

        // 구매 승인 기한 일주일 지나면 구매 취소
        uint nowDate = block.timestamp;
        if(nowDate >= (_transactions[_tokenId].timestamp + 1 weeks)) {
            cancelCarPurchase(_tokenId);
            emit approvalOverdue(block.timestamp, _tokenId, msg.sender);
        }
        else {
        // 클레이와 NFT 정산
        (bool success, ) = payable(_transactions[_tokenId].seller).call{value: _transactions[_tokenId].price}("");
        require(success, "Failed to send KLAY to buyer");
        safeTransferFrom(address(this), _transactions[_tokenId].buyer, _tokenId);

        // 트랜잭션들 정보수정
        _transactions[_tokenId].state = Status.Completed;
        _transactions[_tokenId].timestamp = block.timestamp;
        _prevTransactions[_tokenId].push(_transactions[_tokenId]);

        emit transactionCompleted(block.timestamp, _tokenId, _transactions[_tokenId].seller, _transactions[_tokenId].buyer);
        
        /*
        nft-generator의 매핑 바꿔주는 로직 들어갈 자리
        */

        // Detail과 Transation 삭제
        delete _carDetails[_tokenId];
        delete _transactions[_tokenId];
        }
    }

    // received 구현

    
}