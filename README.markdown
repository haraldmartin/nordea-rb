# Nordea-rb


# First, Please note
I don't take no responsable at all if somethings messes up with your bank account or if you break 
any terms of service (which this lib probably does). It has worked fine for me for a while though.


## What?

nordea-rb is a small Ruby library to access your Nordea bank account and list balances etc. 

It uses the WAP-version (https://mobil.nordea.se) to access the data. This version has many variables names etc
in Swedish so I suppose this only works for the Swedish version right now but it might be easy to adjust it if 
other languages use the same system.

I've only tested it with my own login details so there might be issues if you have a different setup. 


## Storing the account details in Mac OS X's Keychain

On Mac OS X, the recommended way of storing your accounts details is in the built-in Keychain.
Here's how to set it up:

1. Run the application "Keychain Access" (located in /Applications/Utilities)
2. Add a new Password Item (File → New Password Item)
3. You can use which name you'd like for "Keychain Item Name" but by default, nordea-rb will look for an item named "Nordea" (with capital "N")
4. Enter your "personnummer" (Swedish SSN) as "Account Name"
5. Enter your PIN code as "Password". (yes it indicates that its password strength is "weak")
6. Save


## Examples

Creating a new instance

    # use the following account details
    n = Nordea.new("1234567890", "1337")
  
    # or using a hash
    n = Nordea.new(:pnr => "1234567890", :pin => "1337")
  

Getting account details from the Keychain:
  
    # use the default keychain and look for an account called "Nordea"
    n = Nordea.new(:keychain)

    # default keychain with an account named "My Nordea"
    n = Nordea.new(:keychain, :label => 'My Nordea') 

    # Use another keychain file
    n = Nordea.new(:keychain, :label => 'nordea-rb', :keychain_file => '/Users/me/Library/Keychains/login.keychain')


Logging in and out
    
    # manually login and logout
    n = Nordea.new(:keychain)
    n.login
    # ...
    n.logout
    
    
    # If you pass a block, then it will login and logout automatically    
    Nordea.new("1234567890", "1337") do |n|
      # no need to login or out
    end

Listing your accounts

    Nordea.new(...) do |n|
      puts "you have #{n.accounts.size} account(s)"
    end
    
Accessing your account details
    
    Nordea.new(...) do |n|
      account = n.accounts.first
      another_account = n.accounts['Savings']
      puts another_account.name # => "Savings"
      puts account.balance, account.currency, account.to_s
      
      # You can also access accounts using a regexp:
      puts n.accounts[/saving/i]
    end

Getting a list of transactions for an account
    
    Nordea.new(...) do |n|
      savings = n.accounts['Savings']
      puts savings.transactions.size # => displays 20 per page, paging is not yet supported
      
      salary_account = n.accounts['Salary']
      latest = salary_account.transactions.first
      
      puts latest.text        # => the text on the transaction
      puts latest.amount      # => -2000.0
      puts latest.date        # => 2009-01-02
      puts latest.withdrawal? # => true
      puts latest.deposit?    # => false
    end

Transfer money between your own accounts:

    Nordea.new(...) do |n|
      savings = n.accounts['Savings']
      salary_account = n.accounts['Salary']
      
      # transfer 10 SEK from the savings account to the salary account
      savings.withdraw(10.0, 'SEK', :deposit_to => salary_account)
      
      # basically the same transaction:
      salary_account.deposit(10.0, 'SEK', :withdraw_from => savings)
    end


## Command Line Tool

The command line tool is pretty basic right now and it only prints the given account(s) balance(s).
Improving it to do more things (like list transactions etc) would just be a matter of polishing the 
option parser which I throw together quickly. 

Show the balances for the savings account

    ./nordea --pnr=1234567890 --pin=0987 Savings

Show the balances for the accounts named "Savings" and "Salary". Login from keychain

     ./nordea --keychain Savings Salary


## TODO

- Support for transfering money between your own accounts
- Clean up the API and class architecture
- Add support for paging in transactions list
- Build an iPhone optimized web app which uses nordea-rb as backend so we finally can have a better mobile bank


## Credits and license

By [Martin Ström](http://twitter.com/haraldmartin) under the MIT license:

>  Copyright (c) 2009 Martin Ström
>
>  Permission is hereby granted, free of charge, to any person obtaining a copy
>  of this software and associated documentation files (the "Software"), to deal
>  in the Software without restriction, including without limitation the rights
>  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
>  copies of the Software, and to permit persons to whom the Software is
>  furnished to do so, subject to the following conditions:
>
>  The above copyright notice and this permission notice shall be included in
>  all copies or substantial portions of the Software.
>
>  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
>  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
>  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
>  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
>  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
>  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
>  THE SOFTWARE.