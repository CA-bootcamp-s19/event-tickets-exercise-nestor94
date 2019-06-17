pragma solidity ^0.5.0;

    /*
        The EventTicketsV2 contract keeps track of the details and ticket sales of multiple events.
     */
contract EventTicketsV2 {

    /*
        Define an public owner variable. Set it to the creator of the contract when it is initialized.
    */
    address public owner;
    uint   PRICE_TICKET = 100 wei;

    /*
        Create a variable to keep track of the event ID numbers.
    */
    uint public idGenerator;
    
    /*
        Define an Event struct, similar to the V1 of this contract.
        The struct has 6 fields: description, website (URL), totalTickets, sales, buyers, and isOpen.
        Choose the appropriate variable type for each field.
        The "buyers" field should keep track of addresses and how many tickets each buyer purchases.
    */
    struct Event{
        string description;
        string website;
        uint totalTickets;
        uint sales;
        bool isOpen;
        mapping(address => uint) buyers;
    }
    /*
        Create a mapping to keep track of the events.
        The mapping key is an integer, the value is an Event struct.
        Call the mapping "events".
    */
    mapping(uint => Event) events;

    event LogEventAdded(string desc, string url, uint ticketsAvailable, uint eventId);
    event LogBuyTickets(address buyer, uint eventId, uint numTickets);
    event LogGetRefund(address accountRefunded, uint eventId, uint numTickets);
    event LogEndSale(address owner, uint balance, uint eventId);

    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */
    modifier restricted {
        require(msg.sender == owner, 'To perform this operation you must be the creator');
        _;
    }

    modifier isOpen(uint _id) {
        require(events[_id].isOpen);
        _;
    }

    modifier enoughFunds(uint numberOfTickets){
        require(msg.value >= (PRICE_TICKET * numberOfTickets), 'Your submission must be greater or equals to the tickets price');
        _;
        uint amountToRefund = msg.value - (PRICE_TICKET * numberOfTickets);
        msg.sender.transfer(amountToRefund);
    }

    modifier enoughTickets(uint id, uint numberOfTickets){
        uint availableTickets = events[id].totalTickets - events[id].sales;
        require(numberOfTickets <= availableTickets, 'Not enough tickets');
        _;
    }

    modifier hasTickets(uint id){
        require(events[id].buyers[msg.sender] > 0, 'The sender has no tickets available');
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    /*
        Define a function called addEvent().
        This function takes 3 parameters, an event description, a URL, and a number of tickets.
        Only the contract owner should be able to call this function.
        In the function:
            - Set the description, URL and ticket number in a new event.
            - set the event to open
            - set an event ID
            - increment the ID
            - emit the appropriate event
            - return the event's ID
    */
    function addEvent(string memory _description, string memory _url, uint _totalTickets) public restricted returns (uint) {
        events[idGenerator] = Event({
            description: _description, 
            website: _url,
            totalTickets: _totalTickets,
            isOpen: true,
            sales: 0
        });
        emit LogEventAdded(_description, _url, _totalTickets, idGenerator);
        idGenerator += 1;
        return idGenerator - 1;
    }

    /*
        Define a function called readEvent().
        This function takes one parameter, the event ID.
        The function returns information about the event this order:
            1. description
            2. URL
            3. ticket available
            4. sales
            5. isOpen
    */     
    function readEvent(uint _id) public view returns (string memory description, string memory url, uint availableTickets, uint sales, bool _isOpen) {
        Event memory myEvent = events[_id];
        description = myEvent.description;
        url = myEvent.website;
        availableTickets = myEvent.totalTickets - myEvent.sales;
        sales = myEvent.sales;
        _isOpen = myEvent.isOpen;        
        return(description, url, availableTickets, sales, _isOpen);
    }
    /*
        Define a function called buyTickets().
        This function allows users to buy tickets for a specific event.
        This function takes 2 parameters, an event ID and a number of tickets.
        The function checks:
            - that the event sales are open
            - that the transaction value is sufficient to purchase the number of tickets
            - that there are enough tickets available to complete the purchase
        The function:
            - increments the purchasers ticket count
            - increments the ticket sale count
            - refunds any surplus value sent
            - emits the appropriate event
    */

    function buyTickets(uint _id, uint numberOfTickets) public payable isOpen(_id) enoughTickets(_id, numberOfTickets)  enoughFunds(numberOfTickets) {
        Event storage myEvent = events[_id];
        myEvent.sales += numberOfTickets;
        myEvent.buyers[msg.sender] += numberOfTickets;
        emit LogBuyTickets(msg.sender, _id, numberOfTickets);
    }

    /*
        Define a function called getRefund().
        This function allows users to request a refund for a specific event.
        This function takes one parameter, the event ID.
        TODO:
            - check that a user has purchased tickets for the event
            - remove refunded tickets from the sold count
            - send appropriate value to the refund requester
            - emit the appropriate event
    */
    function getRefund(uint _id) public payable isOpen(_id) hasTickets(_id){
        Event storage myEvent = events[_id];
        uint numberOfTickets = myEvent.buyers[msg.sender];
        uint refund = numberOfTickets * PRICE_TICKET;
        msg.sender.transfer(refund);
        myEvent.sales -= numberOfTickets;
        myEvent.buyers[msg.sender] = 0;
        emit LogGetRefund(msg.sender, _id, numberOfTickets);
    }
    /*
        Define a function called getBuyerNumberTickets()
        This function takes one parameter, an event ID
        This function returns a uint, the number of tickets that the msg.sender has purchased.
    */
    function getBuyerNumberTickets(uint _id) public view returns (uint){
        return events[_id].buyers[msg.sender];
    }

    /*
        Define a function called endSale()
        This function takes one parameter, the event ID
        Only the contract owner can call this function
        TODO:
            - close event sales
            - transfer the balance from those event sales to the contract owner
            - emit the appropriate event
    */
    function endSale(uint _id) public payable isOpen(_id) restricted {
        Event storage myEvent = events[_id];
        myEvent.isOpen = false;
        msg.sender.transfer(myEvent.sales * PRICE_TICKET);
        emit LogEndSale(msg.sender, myEvent.sales * PRICE_TICKET, _id);
    }
}
