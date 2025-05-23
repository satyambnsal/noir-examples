// DCI (Data, Context, Interaction) example - keeps objects simple, and binds specific functions to them in their context of use

// ### DATA ###
struct ValueAccount {
    balance: u32,
}

// Primitive functions for data object
trait ValueFunctions {
    fn add(&mut self, val: u32);
    fn sub(&mut self, val: u32);
}

impl ValueFunctions for ValueAccount {
    fn add(&mut self, val: u32) {
        self.balance += val;
    }
    fn sub(&mut self, val: u32) {
        self.balance -= val;
    }
}

// ### CONTEXT ###

// Example purchase context
// Buyer role
trait Buyer {
    fn make_payment(&mut self, val: u32);
}

// impl <T:ValueFunctions> Buyer for T {   // This works in rust
// impl <T> Buyer for T where T:ValueFunctions { // Valid noir, specifies value functions,
//    but gives compilation error on line that calls Buyer function make_payment
impl Buyer for ValueAccount { // context needs to be aware of data object (not just trait)
    fn make_payment(&mut self, val: u32) {
        self.sub(val);
    }
}

// Seller role
trait Seller {
    fn receive_payment(&mut self, val: u32);
}

impl Seller for ValueAccount {
    fn receive_payment(&mut self, val: u32) {
        self.add(val);
    }
}

// Define the purchase context with its generic roles
struct PurchaseContext<B, S> {
    // Roles
    buyer: &mut B,
    seller: &mut S,
}

impl <B, S> PurchaseContext<B, S> where B: Buyer, S: Seller {
    fn do_purchase(&mut self, amount: u32) {
        self.buyer.make_payment(amount); //   Compilation error "No matching impl found for `B: ValueFunctions`" when Buyer uses generic T
        // self.buyer.receive_payment(amount); // correct compiler error, buyer role cannot receive_payment
        self.seller.receive_payment(amount);
    }
}

// ### INTERACTION ###

fn main(start: u32, cost: pub u32) {
    assert(start >= cost, "Not enough start balance");
    // create data object, can use all primitive functions
    let mut acc1: ValueAccount = ValueAccount { balance: start };
    let mut acc2: ValueAccount = ValueAccount { balance: start };

    // create context for data object as
    let mut purchase_context: PurchaseContext<ValueAccount, ValueAccount> = PurchaseContext::<ValueAccount, ValueAccount> { buyer: &mut acc1, seller: &mut acc2 };
    purchase_context.do_purchase(cost);
    assert(acc1.balance == start - cost, "Didn't spend");
    assert(acc2.balance == start + cost, "Didn't receive");
}

#[test]
fn test_generic_traits() {
    main(10, 5);
}
