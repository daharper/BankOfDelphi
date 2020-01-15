unit uBankTests;

interface

uses
  System.SysUtils, DUnitX.TestFramework, uBank;

type
  { Asserts the veracity of the bank and associated classes }

  [TestFixture]
  TBankTest = class(TObject)
  private
    FBank: TBank;
  public
    [Setup]
    procedure Setup;

    [Teardown]
    procedure Teardown;

    [Test]
    [TestCase('Create valid account','David')]
    [TestCase('Create valid account','Ty')]
    [TestCase('Create valid account','ABCDEABCDEABCDEABCDE')]
    procedure TestCreateAccount(const AAccountName: string);

    [Test]
    procedure TestInvalidNameRejected();

    [Test]
    procedure TestDeposit();

    [Test]
    procedure TestWithdraw();

    [Test]
    procedure TestMiniStatement();
  end;

implementation

{ TMyTestObject }

{------------------------------------------------------------------------------------------------------------}
procedure TBankTest.TestCreateAccount(const AAccountName: string);
var
  Account: TAccount;
begin
  Account := FBank.CreateAccount(AAccountName);

  Assert.AreEqual(AAccountName, Account.Name);
  Assert.IsTrue(Account.Balance = 0, 'New account balance should be 0.');
end;

{------------------------------------------------------------------------------------------------------------}
procedure TBankTest.TestDeposit();
var
  Account: TAccount;
begin
  Account := FBank.CreateAccount('David');

  Assert.WillRaiseWithMessage(
    procedure begin Account.Add(nil); end,
    EArgumentException,
    'Invalid transaction error.');

  Assert.WillRaiseWithMessage(
    procedure begin Account.Add(TDeposit.Create(0)); end,
    EArgumentException,
    'Invalid deposit amount error.');

  Account.Add(TDeposit.Create(50));
  Assert.IsTrue(Account.Balance = 50);

  Account.Add(TDeposit.Create(25));
  Assert.IsTrue(Account.Balance = 75);
end;

{------------------------------------------------------------------------------------------------------------}
procedure TBankTest.TestWithdraw;
var
  Account: TAccount;
  Withdrawal: TWithdrawal;
begin
  Account := FBank.CreateAccount('David');

  Assert.WillRaiseWithMessage(
    procedure begin Account.Add(nil); end,
    EArgumentException,
    'Invalid transaction error.');

  Assert.WillRaiseWithMessage(
    procedure begin Account.Add(TWithdrawal.Create(0)); end,
    EArgumentException,
    'Invalid withdrawal amount error.');

  Withdrawal := TWithdrawal.Create(50);

  Assert.WillRaiseWithMessage(
    procedure begin Account.Add(Withdrawal); end,
    EArgumentException,
    'Insufficient funds error.');

  Account.Add(TDeposit.Create(125));
  Account.Add(Withdrawal);
  Assert.IsTrue(Account.Balance = 75);

  Account.Add(TWithdrawal.Create(45));
  Assert.IsTrue(Account.Balance = 30);
end;

{------------------------------------------------------------------------------------------------------------}
procedure TBankTest.TestInvalidNameRejected();
begin
  Assert.WillRaiseWithMessage(
    procedure begin FBank.CreateAccount('AB#@323'); end,
    EArgumentException,
    'Account name must contain letters only.');

  Assert.WillRaiseWithMessage(
    procedure begin FBank.CreateAccount(''); end,
    EArgumentException,
    'Account name is missing a value.');

  Assert.WillRaiseWithMessage(
    procedure begin FBank.CreateAccount('ABCDEABCDEABCDEABCDEA'); end,
    EArgumentException,
    'Account name must be between 2-20 characters in length.');

  Assert.WillRaiseWithMessage(
    procedure begin FBank.CreateAccount('A'); end,
    EArgumentException,
    'Account name must be between 2-20 characters in length.');
end;

{------------------------------------------------------------------------------------------------------------}
procedure TBankTest.TestMiniStatement;
const
  Expected =  'Bank of Delphi MiniStatement' + sLineBreak + sLineBreak +
              'Act: David                                         Bal: $98.00' + sLineBreak +
              #9 + '6    15/01/20 deposit         $25.00' + sLineBreak +
              #9 + '7    15/01/20 withdrawal      $10.00' + sLineBreak +
              #9 + '8    15/01/20 deposit         $100.00' + sLineBreak +
              #9 + '9    15/01/20 withdrawal      $10.00' + sLineBreak +
              #9 + '10   15/01/20 withdrawal      $7.00' + sLineBreak + sLineBreak +
              'Act: Thomas                                        Bal: $453.00' + sLineBreak +
              #9 + '11   15/01/20 deposit         $500.00' + sLineBreak +
              #9 + '12   15/01/20 withdrawal      $10.00' + sLineBreak +
              #9 + '13   15/01/20 withdrawal      $40.00' + sLineBreak +
              #9 + '14   15/01/20 deposit         $3.00';
var
  David: TAccount;
  Thomas: TAccount;
  Statement: string;
begin
  David := FBank.CreateAccount('David');
  David.Deposit(25);
  David.Withdraw(10);
  David.Deposit(100);
  David.Withdraw(10);
  David.Withdraw(7);

  Thomas := FBank.CreateAccount('Thomas');
  Thomas.Deposit(500);
  Thomas.Withdraw(10);
  Thomas.Withdraw(40);
  Thomas.Deposit(3);

  Statement := TMiniStatement.Generate(FBank);
  Assert.AreEqual(Expected, Statement);
end;

{------------------------------------------------------------------------------------------------------------}
procedure TBankTest.Setup;
begin
  FBank := TBank.Create;
end;

{------------------------------------------------------------------------------------------------------------}
procedure TBankTest.Teardown;
begin
  if Assigned(FBank) then
    FreeAndNil(FBank);
end;

initialization
  TDUnitX.RegisterTestFixture(TBankTest);
end.
