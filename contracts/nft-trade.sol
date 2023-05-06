// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./nft-sale-registration.sol";

contract CarNFT_Trade is CarNFT_SaleRegistration, IKIP17Receiver{

    // 구매자가 클레이를 지불하여 구매 요청을 보내는 함수
    function reserveCar(uint _tokenId) external payable registeredForSale(_tokenId) correctState(_tokenId, Status.Registered) {
        // 이미 거래중이면 revert
        require(isTrading(_tokenId) || msg.sender != _transactions[_tokenId].seller , "This car is currently being traded");
        // 보낸 클레이가 가격보다 적으면 revert
        require(msg.value >= _carDetails[_tokenId].price, "Not enough KLAY to buy this car");
        
        (bool success, ) = payable(address(this)).call{value:msg.value}("");
        require(success, "Failed to send KLAY to Contract");
    
        _transactions[_tokenId].buyer = msg.sender;
        _transactions[_tokenId].state = Status.Reserved;
        _transactions[_tokenId].timestamp = block.timestamp;
    }

    // 판매자가 NFT를 CA로 전송하여 판매 승인하는 함수
    function sendCar(uint _tokenId) external onlyNFTOwner(_tokenId) registeredForSale(_tokenId) correctState(_tokenId, Status.Reserved) {
        // nft를 판매자가 ca에게 전송
        safeTransferFrom(_transactions[_tokenId].seller, address(this), _tokenId);
        _transactions[_tokenId].state = Status.Sended;
        _transactions[_tokenId].timestamp = block.timestamp;
    }

    // 구매자가 최종 구매 승인하는 함수
    function confirmBuying(uint _tokenId) external registeredForSale(_tokenId) correctState(_tokenId, Status.Sended) {
        // msg.sender가 구매자가 아니면 revert 
        require(msg.sender == _transactions[_tokenId].buyer, "Caller is not the buyer of the car");

        // 구매 승인 기한 일주일 지나면 구매 취소
        uint nowDate = block.timestamp;
        if(nowDate >= (_transactions[_tokenId].timestamp + 1 weeks)) {
            cancelCarPurchase(_tokenId);
        }
        else {
            _completeTransaction(_tokenId);
        }
    }

    function _completeTransaction(uint _tokenId) private {
        // 클레이와 NFT 정산
        (bool success, ) = payable(_transactions[_tokenId].seller).call{value: _transactions[_tokenId].price}("");
        require(success, "Failed to send KLAY to buyer");
        safeTransferFrom(address(this), _transactions[_tokenId].buyer, _tokenId);

        // 트랜잭션들 정보수정
        _transactions[_tokenId].state = Status.Completed;
        _transactions[_tokenId].timestamp = block.timestamp;
        _prevTransactions[_tokenId].push(_transactions[_tokenId]);

        // 판매 목록에서 내리기
        _popOnSale(_tokenId);

        /*
        nft-generator의 매핑 바꿔주는 로직 들어갈 자리
        */

        address seller = _transactions[_tokenId].seller;
        address buyer = _transactions[_tokenId].buyer;

        emit transactionCompleted(block.timestamp, _tokenId, _transactions[_tokenId].seller, _transactions[_tokenId].buyer);
    }

    /*
     * 판매를 취소하는 함수
     */
    function cancelCarSale(uint _tokenId) public registeredForSale(_tokenId) {
        require(msg.sender == _transactions[_tokenId].seller, "Only the seller can cancel the sale");

        // CA의 NFT approve 취소 
        _approve(address(0), _tokenId);
        // 거래 목록에서 내리기
        _transactions[_tokenId].state == Status.Canceled;
        _popOnSale(_tokenId);

        if(ownerOf(_tokenId) == address(this)){
            safeTransferFrom(address(this), msg.sender, _tokenId);
        }
    }

    /*
     * 구매를 취소하는 함수
     * 구매자가 호출 or 구매 승인 기한 지났을 경우 호출
     */
    function cancelCarPurchase(uint _tokenId) public {
        require(isTrading(_tokenId), "This car is not trading.");
        require(msg.sender == _transactions[_tokenId].buyer, "The caller is not the buyer.");

        // 차량의 상태를 Registered로 바꿈
        _transactions[_tokenId].timestamp = _carDetails[_tokenId].registDate;
        _transactions[_tokenId].buyer = address(0);
        _transactions[_tokenId].state = Status.Registered;

        if(ownerOf(_tokenId) == address(this)){
            safeTransferFrom(address(this), _transactions[_tokenId].seller, _tokenId);
        }
    }

    function onKIP17Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4){
        return this.onKIP17Received.selector;
    }
}