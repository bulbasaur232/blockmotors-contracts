// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./nft-sale-registration.sol";

contract CarNFT_Trade is CarNFT_SaleRegistration, IKIP17Receiver{

    // 구매자가 클레이를 지불하여 구매 요청을 보내는 함수
    function reserveCar(uint _tokenId) external payable registeredForSale(_tokenId) correctState(_tokenId, Status.Registered) {
        // 이미 거래중이면 revert
        require(!isTrading(_tokenId) || msg.sender != _transactions[_tokenId].seller , "This car is currently being traded");
        // 보낸 클레이가 가격과 다르면 revert
        require(msg.value == _carDetails[_tokenId].price, "You must pay the correct price");
        
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
        
        // nft-generator.sol의 주소-차량id 매핑수정
        remapTokenId(_transactions[_tokenId].seller, _transactions[_tokenId].buyer, _tokenId);
        
        emit transactionCompleted(block.timestamp, _tokenId, _transactions[_tokenId].seller, _transactions[_tokenId].buyer);

        // 판매 목록에서 내리기
        _popOnSale(_tokenId);
    }

    /**
     * 판매를 취소하는 함수
     */
    function cancelCarSale(uint _tokenId) public registeredForSale(_tokenId) {
        require(msg.sender == _transactions[_tokenId].seller, "Only the seller can cancel the sale");

        // CA의 NFT approve 취소 
        _approve(address(0), _tokenId);
        // KLAY와 NFT 환불
        _refund(_tokenId);
        // 판매 목록에서 내리기
        _popOnSale(_tokenId);
    }

    /**
     * 구매를 취소하는 함수
     * 구매자가 호출 or 구매 승인 기한 지났을 경우 호출
     */
    function cancelCarPurchase(uint _tokenId) public {
        require(isTrading(_tokenId), "This car is not trading.");
        require(msg.sender == _transactions[_tokenId].buyer, "The caller is not the buyer.");

        // KLAY와 NFT 환불
        _refund(_tokenId);
        // 차량의 상태를 Registered로 바꿈
        _transactions[_tokenId].timestamp = _carDetails[_tokenId].registDate;
        _transactions[_tokenId].buyer = address(0);
        _transactions[_tokenId].state = Status.Registered;
    }

    /**
    * 거래 취소 시 KLAY와 NFT를 돌려주는 함수
    */
    function _refund(uint _tokenId) private {
        // 구매자에게 KLAY 환불
        if(isTrading(_tokenId)){
            (bool success, ) = payable(_transactions[_tokenId].buyer).call{value: _transactions[_tokenId].price}("");
            require(success, "Failed to send KLAY to buyer");
        }

        if(ownerOf(_tokenId) == address(this)){
            safeTransferFrom(address(this), _transactions[_tokenId].seller, _tokenId);
        }
    }

    // 차량을 판매 목록에서 제거하는 함수
    function _popOnSale(uint _tokenId) private {
        require(_carsOnSale.length > 0, "No cars for sale");
        uint idx = 0;
        for(uint i = 0; i < _carsOnSale.length; i++){
            if(_carsOnSale[i] == _tokenId){
                idx = i;
                break;
            }
        }
        require(_carsOnSale[idx] == _tokenId, "This car is not for sale");

        _carsOnSale[idx] = _carsOnSale[_carsOnSale.length - 1];
        _carsOnSale.pop();

        // Detail과 Transation 삭제
        delete _carDetails[_tokenId];
        delete _transactions[_tokenId];
    }

    function onKIP17Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4){
        return this.onKIP17Received.selector;
    }
    
    receive() external payable {

    }

    fallback() external payable {

    }
}