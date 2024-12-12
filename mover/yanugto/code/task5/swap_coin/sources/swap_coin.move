module swap_coin::swap_coin{
  
  use my_coin::faucet_coin::{FAUCET_COIN};
  use my_coin::usd::{USD};
  use sui::balance::{Supply};
  use sui::balance::Balance;
  use sui::transfer::{share_object,transfer,public_transfer};
  use sui::coin;
  use sui::coin::{Coin};

  public struct Pool has key {
    id: UID,
    a_coin_balance: Balance<FAUCET_COIN>,
    b_coin_balance: Balance<USD>,
    lp: Supply<LPCoin<FAUCET_COIN,USD>>,
  }

  // LP Coin is a token that represents the ownership of the pool
  public struct LPCoin<FAUCET_COIN,USD> has drop{}


  fun init(ctx: &mut TxContext){
    // Make the pool object public
    share_object(Pool{
      id: object::new(ctx),
      a_coin_balance: balance::zero<FAUCET_COIN>(),
      b_coin_balance: balance::zero<USD>(),
      lp: balance::create_supply(LPCoin<FAUCET_COIN,USD>{}),
    });
  }

  // Any user can deposit a_coin and b_coin to the pool
  public fun deposit(pool: &mut Pool, a_coin: Coin<FAUCET_COIN>, b_coin: Coin<USD>, ctx: &mut TxContext){
    let poll_a_coin_value = pool.a_coin_balance.value();
    let poll_b_coin_value = pool.b_coin_balance.value();

    let a_coin_value = a_coin.value();
    let b_coin_value = b_coin.value();

    // Make sure the ratio of a_coin to b_coin is the original ratio
    assert!(pool_a_coin_value/pool_b_coin_value != a_coin_value/b_coin_value,0x001); 

    pool.a_coin_balance.join(coin::into_balance(a_coin)); 
    pool.b_coin_balance.join(coin::into_balance(b_coin)); 


    // This represents the deposit certificate
    let lp_pool = pool.lp.increase_supply(u64::sqrt(a_coin_value * b_coin_value));

    // Transfer the deposit certificate to the sender
    public_transfer(coin::from_balance(lp_pool,ctx), ctx.sender());
  }

  // Any user can withdraw a_coin and b_coin from the pool by providing the deposit certificate
  public fun withdraw(pool: &mut Pool, lp: Coin<LPCoin<FAUCET_COIN,USD>>, ctx: &mut TxContext){
    let lp_value = lp.value();

    //let a_coin_value = pool.a_coin_balance.value() * lp_value / pool.lp.value();
    //let b_coin_value = pool.b_coin_balance.value() * lp_value / pool.lp.value();

    let a_coin = coin::from_balance(pool.a_coin_balance.split(a_coin_value),ctx);
    let b_coin = coin::from_balance(pool.b_coin_balance.split(b_coin_value),ctx);

    public_transfer(a_coin, ctx.sender());
    public_transfer(b_coin, ctx.sender());
  }

  public fun swap_a_to_b(pool: &mut Pool, a_coin: Coin<FAUCET_COIN>,ctx: &mut TxContext){
    let pool_a_coin_value = pool.a_coin_balance.value();
    let pool_b_coin_value = pool.b_coin_balance.value();

    let pool_total_value = pool_a_coin_value * pool_b_coin_value;

    let a_coin_value = a_coin.value();

    let new_total_a_coin_value = pool_a_coin_value + a_coin_value;

    let swaped_b_coin_value = pool_b_coin_value - (pool_total_value / new_total_a_coin_value);

    pool.a_coin_balance.join(coin::into_balance(a_coin));

    public_transfer(coin::from_balance(coin::from_value(pool.b_coin_balance.split(swaped_b_coin_value)),ctx), ctx.sender());
  }

  public fun swap_b_to_a(pool: &mut Pool, b_coin: Balance<USD>, ctx: &mut TxContext){
    let pool_a_coin_value = pool.a_coin_balance.value();
    let pool_b_coin_value = pool.b_coin_balance.value();

    let pool_total_value = pool_a_coin_value * pool_b_coin_value;

    let b_coin_value = b_coin.value();

    let new_total_b_coin_value = pool_b_coin_value + b_coin_value;

    let swaped_a_coin_value = pool_a_coin_value - (pool_total_value / new_total_b_coin_value);

    pool.b_coin_balance.join(coin::into_balance(b_coin));

    public_transfer(coin::from_balance(coin::from_value(pool.a_coin_balance.split(swaped_a_coin_value)),ctx), ctx.sender());
  }

}