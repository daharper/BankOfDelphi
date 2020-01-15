unit uBank;

interface

uses
  System.Generics.Collections;
  
type
  { Base class for all our transactions }
  
  TTransaction = class
  private                                                         
    FId: integer;
    FAmount: Currency;
    FDateTime: TDateTime;
    FDescription: string;

    class var
      FIdSeed: integer;
      
  protected
    constructor Create(AAmount: Currency; ADescription: string);    
  public
    property Id: integer read FId;
    property Amount: Currency read FAmount;
    property DateTime: TDateTime read FDateTime;
    property Description: string read FDescription;
    
    function ToString: string; override;    
  end;

  { Represents a deposit }
  
  TDeposit = class(TTransaction)
  public
    constructor Create(AAmount: Currency);
  end;

  { Represents a withdrawal }
  
  TWithdrawal = class(TTransaction)
  public
    constructor Create(AAmount: Currency);
  end;
  
  { an account at the bank }
  
  TAccount = class
  private
    FName: string;
    FTransactions: TObjectList<TTransaction>;
    
    function GetBalance: Currency;
  public
    constructor Create(AName: string);
    destructor Destroy; override;

    property Name: string read FName;
    property Balance: Currency read GetBalance;

    function GetEnumerator: TEnumerator<TTransaction>;
            
    procedure Withdraw(AAmount: Currency);
    procedure Deposit(AAmount: Currency);
    
    procedure Add(ATransaction: TTransaction);  
              
    class procedure ValidateName(AName: string);
  end;

  { the bank }
  
  TBank = class
  private
    FAccounts: TObjectDictionary<string, TAccount>;
  public
    constructor Create;
    destructor Destroy; override;

    function GetEnumerator: TEnumerator<TAccount>;    
    function CreateAccount(AName: string): TAccount;
  end;

  { the mini statement }

  TMiniStatement = class  
    class function Generate(ABank: TBank): string;
  end;

implementation

uses
  System.SysUtils, System.Generics.Defaults, System.RegularExpressions;

{ TBank }

{------------------------------------------------------------------------------------------------------------}
constructor TBank.Create;
begin
  FAccounts := TObjectDictionary<string, TAccount>.Create(
    [doOwnsValues],
    TIStringComparer.Ordinal);
end;

{------------------------------------------------------------------------------------------------------------}
function TBank.CreateAccount(AName: string): TAccount;
begin
  TAccount.ValidateName(AName);
  
  if FAccounts.ContainsKey(AName) then
    raise EArgumentException.Create('Account already exists error: ' + AName);

  Result := TAccount.Create(AName);
  FAccounts.Add(Result.Name, Result);
end;

{------------------------------------------------------------------------------------------------------------}
destructor TBank.Destroy;
begin
  if Assigned(FAccounts) then
    FreeAndNil(FAccounts);

  inherited;
end;

{------------------------------------------------------------------------------------------------------------}
function TBank.GetEnumerator: TEnumerator<TAccount>;
begin
  Result := FAccounts.Values.GetEnumerator;
end;

{ TAccount }

{------------------------------------------------------------------------------------------------------------}
procedure TAccount.Add(ATransaction: TTransaction);
begin
  if (not Assigned(ATransaction)) or (ATransaction.Amount <= 0) then
    raise EArgumentException.Create('Invalid transaction error.');

  if (ATransaction is TWithdrawal) and (ATransaction.Amount > Balance) then
    raise EArgumentException.Create('Insufficient funds error.');
      
  FTransactions.Add(ATransaction);
end;

{------------------------------------------------------------------------------------------------------------}
constructor TAccount.Create(AName: string);
begin
  ValidateName(AName);     
  FName := AName.Trim;
  FTransactions := TObjectList<TTransaction>.Create;
end;

{------------------------------------------------------------------------------------------------------------}
procedure TAccount.Deposit(AAmount: Currency);
begin
  Add(TDeposit.Create(AAmount));
end;

{------------------------------------------------------------------------------------------------------------}
destructor TAccount.Destroy;
begin
  if Assigned(FTransactions) then
    FreeAndNil(FTransactions);
      
  inherited;
end;

{------------------------------------------------------------------------------------------------------------}
function TAccount.GetBalance: Currency;
var
  Transaction: TTransaction;
begin
  Result := 0;
  
  for Transaction in FTransactions do
    if Transaction is TDeposit then
      Result := Result + Transaction.Amount
    else
      Result := Result - Transaction.Amount;    
end;

{------------------------------------------------------------------------------------------------------------}
function TAccount.GetEnumerator: TEnumerator<TTransaction>;
begin
  Result := FTransactions.GetEnumerator;
end;

{------------------------------------------------------------------------------------------------------------}
class procedure TAccount.ValidateName(AName: string);
begin
  if string.IsNullOrWhitespace(AName) then
    raise EArgumentException.Create('Account name is missing a value.');

  if (AName.Length < 2) or (AName.Length > 20) then
    raise EArgumentException.Create('Account name must be between 2-20 characters in length.');

  if not TRegEx.IsMatch(AName, '^[A-Z]*$', [roIgnoreCase]) then
    raise EArgumentException.Create('Account name must contain letters only.');          
end;

{------------------------------------------------------------------------------------------------------------}
procedure TAccount.Withdraw(AAmount: Currency);
begin
  Add(TWithdrawal.Create(AAmount));
end;

{ TTransaction }

{------------------------------------------------------------------------------------------------------------}
constructor TTransaction.Create(AAmount: Currency; ADescription: string);
begin
  if (AAmount < 0) then
    raise EArgumentException.Create('Transaction amount must be greater than zero');

  FId := AtomicIncrement(FIdSeed);  
  FAmount := AAmount;
  FDateTime := Now;
  FDescription := ADescription;
end;

{------------------------------------------------------------------------------------------------------------}
function TTransaction.ToString: string;
begin
  Result := Format('%-4s %s %-15s %s', [
    FId.ToString,
    FormatDateTime('dd/mm/yy', FDateTime),
    FDescription,
    CurrToStrF(FAmount, ffCurrency, 2)]);   
end;

{ TDeposit }

{------------------------------------------------------------------------------------------------------------}
constructor TDeposit.Create(AAmount: Currency);
begin
  if AAmount <= 0 then
    raise EArgumentException.Create('Invalid deposit amount error.');   

  inherited Create(AAmount, 'deposit');
end;

{ TWithdrawal }

{------------------------------------------------------------------------------------------------------------}
constructor TWithdrawal.Create(AAmount: Currency);
begin
  if AAmount <= 0 then
    raise EArgumentException.Create('Invalid withdrawal amount error.');   
    
  inherited Create(AAmount, 'withdrawal');
end;

{ TMiniStatement }

{------------------------------------------------------------------------------------------------------------}
class function TMiniStatement.Generate(ABank: TBank): string;
var
  Sb: TStringBuilder;
  Balance: string;
  Account: TAccount;
  Transaction: TTransaction;  
  
begin
  Sb := TStringBuilder.Create;

  Sb.Append('Bank of Delphi MiniStatement')
    .AppendLine;

  for Account in ABank do begin
    Balance := CurrToStrF(Account.GetBalance, ffCurrency, 2);
    
    Sb.AppendLine
      .Append(Format('Act: %-45s Bal: %s', [Account.Name, Balance]))
      .AppendLine;
       
    for Transaction in Account do begin
      sb.Append(#9 + Transaction.ToString)
        .AppendLine;
    end;
  end;
  
  Result := sb.ToString.Trim;
end;

end.
