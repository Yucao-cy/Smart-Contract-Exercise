pragma solidity ^0.5.15;

contract Accommodation {
    address payable public renter;
    address payable public owner;

    uint public totalRooms = 0;
    uint public totalAgreements = 0;
    uint public totalRents = 0;

    struct RoomDetail {
        uint roomId;
        uint agreementId;
        string roomName;
        string roomLocation;
        uint monthlyRent;
        uint deposit;
        uint createdAt;
        bool isAvailable;
        address payable ownerAddress;
        address payable tenantAddress;
    }

    mapping(uint => RoomDetail) public rooms;

    struct LeaseAgreement {
        uint roomId;
        uint agreementId;
        string roomName;
        string roomLocation;
        uint monthlyRent;
        uint deposit;
        uint duration;
        uint agreementTimestamp;
        address payable tenantAddr;
        address payable ownerAddr;
    }

    mapping(uint => LeaseAgreement) public agreements;

    struct RentalPayment {
        uint rentId;
        uint roomId;
        uint agreementId;
        string roomName;
        string roomLocation;
        uint monthlyRent;
        uint paymentTimestamp;
        address payable tenantAddr;
        address payable ownerAddr;
    }

    mapping(uint => RentalPayment) public rentPayments;

    modifier ownerOnly(uint roomIndex) {
        require(msg.sender == rooms[roomIndex].ownerAddress, "Access restricted to the room owner");
        _;
    }

    modifier notOwner(uint roomIndex) {
        require(msg.sender != rooms[roomIndex].ownerAddress, "Access restricted to the tenant");
        _;
    }

    modifier roomAvailable(uint roomIndex) {
        require(rooms[roomIndex].isAvailable, "Room is occupied");
        _;
    }

    modifier sufficientRent(uint roomIndex) {
        require(msg.value >= rooms[roomIndex].monthlyRent, "Insufficient funds for rent");
        _;
    }

    modifier sufficientAgreementFee(uint roomIndex) {
        require(msg.value >= rooms[roomIndex].monthlyRent + rooms[roomIndex].deposit, "Insufficient funds for agreement");
        _;
    }

    modifier isTenant(uint roomIndex) {
        require(msg.sender == rooms[roomIndex].tenantAddress, "No existing agreement found");
        _;
    }

    modifier agreementNotExpired(uint roomIndex) {
        uint agreementExpiry = agreements[rooms[roomIndex].agreementId].agreementTimestamp + agreements[rooms[roomIndex].agreementId].duration;
        require(now < agreementExpiry, "Lease agreement has ended");
        _;
    }

    modifier rentDue(uint roomIndex) {
        require(now >= rooms[roomIndex].createdAt + 30 days, "Rent payment is not due yet");
        _;
    }

    function addNewRoom(string memory roomName, string memory roomLocation, uint rentAmount, uint depositAmount) public {
        totalRooms++;
        rooms[totalRooms] = RoomDetail(totalRooms, 0, roomName, roomLocation, rentAmount, depositAmount, 0, true, msg.sender, address(0));
    }

    function enterAgreement(uint roomIndex) public payable notOwner(roomIndex) sufficientAgreementFee(roomIndex) roomAvailable(roomIndex) {
        address payable roomOwner = rooms[roomIndex].ownerAddress;
        uint totalFee = rooms[roomIndex].monthlyRent + rooms[roomIndex].deposit;
        roomOwner.transfer(totalFee);

        totalAgreements++;
        rooms[roomIndex].tenantAddress = msg.sender;
        rooms[roomIndex].isAvailable = false;
        rooms[roomIndex].createdAt = now;
        rooms[roomIndex].agreementId = totalAgreements;

        agreements[totalAgreements] = LeaseAgreement(roomIndex, totalAgreements, rooms[roomIndex].roomName, rooms[roomIndex].roomLocation, rooms[roomIndex].monthlyRent, rooms[roomIndex].deposit, 365 days, now, msg.sender, roomOwner);

        totalRents++;
        rentPayments[totalRents] = RentalPayment(totalRents, roomIndex, rooms[roomIndex].agreementId, rooms[roomIndex].roomName, rooms[roomIndex].roomLocation, rooms[roomIndex].monthlyRent, now, msg.sender, roomOwner);
    }

    function submitRent(uint roomIndex) public payable isTenant(roomIndex) rentDue(roomIndex) sufficientRent(roomIndex) {
        address payable roomOwner = rooms[roomIndex].ownerAddress;
        roomOwner.transfer(rooms[roomIndex].monthlyRent);
        
        totalRents++;
        rentPayments[totalRents] = RentalPayment(totalRents, roomIndex, rooms[roomIndex].agreementId, rooms[roomIndex].roomName, rooms[roomIndex].roomLocation, rooms[roomIndex].monthlyRent, now, msg.sender, roomOwner);
    }

    function closeAgreement(uint roomIndex) public payable ownerOnly(roomIndex) {
        rooms[roomIndex].isAvailable = true;
        address payable tenant = rooms[roomIndex].tenantAddress;
        uint depositBack = rooms[roomIndex].deposit;
        tenant.transfer(depositBack);
    }

    function terminateAgreement(uint roomIndex) public ownerOnly(roomIndex) agreementNotExpired(roomIndex) {
        rooms[roomIndex].isAvailable = true;
    }
}
