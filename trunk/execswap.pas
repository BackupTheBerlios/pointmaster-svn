{$R-,S-,F-}

{Thanks to Chris Franzen of O.K.SOFT Software, West Germany
 who added the swap-to-disk capability to our EMSEXEC unit}

unit ExecSwap;
  {-Dos shell with swapping to Ems or disk}

{Notes on using this unit:
 ----------------------------------------------------------------------
 1. To save as much normal memory as possible, keep this unit as near as
    possible to the END of the program's USES statement, and keep the main
    unit of the program as small as possible.
 2. It is the caller's responsibility to assure that all interrupt vectors
    have been restored before calling ExecWithSwap. If they haven't been,
    it is likely that the shell will overwrite the interrupt handler and
    the system will crash.
 3. ExecWithSwap uses EMS memory for swapping, or a disk file on the logged
    disk if no EMS board is installed. See the declaration of SwapFilename
    for the swapfile's filename.
 4. If the Turbo Pascal heap will be empty or otherwise saved at the time
    ExecWithSwap is called, pass HeapOrg as the parameter to
    PrepareExecWithSwap. To save the entire heap as well, pass
    Ptr(seg(FreePtr^)+$1000, 0) as the parameter to PrepareExecWithSwap. To
    save all but the free list, pass HeapPtr as the parameter to InstallEms
    (this is valid only if the free list was saved before the
    PrepareExecWithSwap call -- see the ExecDos procedure in the TPDOS unit
    of Turbo Professional for an example of saving the free list).
 5. PrepareExecWithSwap will return false if there was not enough EMS
    memory available, an error accessing the EMM, not enough disk space
    available, or an error creating the swap file.
 6. ExecWithSwap returns error codes in the variable DosError, just like
    the Exec procedure in the DOS unit. Besides normal DOS error codes,
    it will return DosError = 1 if there is an error mapping the EMS device
    or accessing the swap file. An error accessing the swap file will also
    put the default fatal error handler into action (intr 24h); because we
    can't catch any interrupt vectors, there is no (save) way to avoid this.
 7. If ExecWithSwap encounters an error while restoring the state of memory
    after the Exec is done, it will simply halt and return to DOS. There
    is no reliable way for it to recover. The most likely reason for this
    to occur is if a memory resident program is installed while the shell
    is active. Other possible reasons are deleting the swap file or
    deallocating the EMS block while the shell is active.
 8. This unit will automatically deallocate the EMS memory block/erase the
    swap file when the program halts.
 9. Because the swap file will be allocated with a normal DOS call and
    kept opened while the shell is active, it depends on the DOS version
    if the file will be 'spawned' to the child process. If so, the child
    process loses one file handle. (DOS 3.3 doesn't make the file available
    to the child process, for example)
}

interface

uses
  Dos;

var
  NoOfBytesSwapped : LongInt;     {Bytes to swap to EMS/disk}
  EmsAllocated : Boolean;         {True when EMS allocated for swap}
  SwapFileAllocated : Boolean;    {True when file allocated for swap}

procedure ExecWithSwap(Path, CmdLine : String);
  {-DOS shell with swapping to EMS or disk}

function PrepareExecWithSwap(LastToSave : Pointer;
                             SwapFileName : String) : Boolean;
  {-Set up for a shell with swapping, returning true if successful}

procedure RemoveExecWithSwap;
  {-Deallocate EMS space or erase swap file, whichever was allocated}

  {---------------------------------------------------------------}
  {Following routines are interfaced for other general purpose use}

function EmsInstalled : Boolean;
  {-Return true if EMS driver installed}

function EmsPageFrame : Word;
  {-Returns the page frame base segment}

function AllocateEmsPages(NumPages : Word) : Word;
  {-Allocate the indicated number of pages and returns a handle}

procedure DeallocateEmsHandle(Handle : Word);
  {-Deallocate the memory associated with the indicated handle}

  {==================================================================}

implementation

const
  EmsPageSize = 16384;
var
  EmsHandle : Word;
  FrameSeg : Word;

const
  SwapFileAttr = 4;               {Swap file attribute; hidden+system bits set}
var
  SwapFileHandle : Word;
  SwapName : String[80];          {Name of file opened for swapping}
  SaveExit : Pointer;

type
  DiskClass = (
    Floppy360, Floppy720, Floppy12, Floppy144, OtherFloppy, Bernoulli,
    HardDisk, RamDisk, SubstDrive, UnknownDisk, InvalidDrive);
  {$L EXECSWAP}
  procedure ExecWithSwap(Path, CmdLine : String); external;

  {-DOS shell with swapping to EMS or disk}
  procedure FirstToSave; external;
  {-Marks start of region saved to EMS or disk}
  function PtrDiff(H, L : Pointer) : LongInt; external;
  {-Return the number of bytes between H^ and L^. H is the higher address}
  function EmsInstalled : Boolean; external;
  {-Return true if EMS driver installed}
  function EmsPageFrame : Word; external;
  {-Returns the page frame base segment}
  function AllocateEmsPages(NumPages : Word) : Word; external;
  {-Allocates the indicated number of pages and returns a handle}
  procedure DeallocateEmsHandle(Handle : Word); external;
  {-Deallocates the indicated handle and the memory associated with it}

  procedure DeallocateFileHandle(FileHandle : Word);
    {-Close, unhide, and erase the swap file}
  var
    Regs : Registers;
  begin
    with Regs do begin
      AH := $3E;                  {DOS close file handle func#}
      BX := FileHandle;
      MSDOS(Regs);                {Errors ignored here}
      AH := $43;                  {DOS get/set file attr func#}
      AL := 1;                    {Set attr}
      CX := 0;                    {Reset all attributes}
      DS := Seg(SwapName);
      DX := Ofs(SwapName[1]);
      MSDOS(Regs);
      AH := $41;                  {DOS delete file func#}
      MSDOS(Regs);                {Errors ignored here}
    end;
  end;

  procedure RemoveExecWithSwap;
    {-Deallocate EMS space or swap file, whichever was allocated}
  begin
    if EmsAllocated then begin
      DeallocateEmsHandle(EmsHandle);
      EmsAllocated := False;
    end else if SwapFileAllocated then begin
      DeallocateFileHandle(SwapFileHandle);
      SwapFileAllocated := False;
    end;
  end;

  function AllocateSwapFile(var FileHandle : Word) : Boolean;
    {-Create and hide the swap file}
  var
    Regs : Registers;
  begin
    AllocateSwapFile := False;
    with Regs do begin
      AH := $43;                  {DOS get/set file attribute func#}
      AL := 1;                    {Set attr}
      CX := 0;                    {Reset all attributes}
      DS := Seg(SwapName);
      DX := Ofs(SwapName[1]);
      MSDOS(Regs);                {Errors are OK}
      AH := $3C;                  {DOS create file handle with overwrite func#}
      CX := SwapFileAttr;         {DS,DX still set}
      MSDOS(Regs);
      if Odd(Flags) then
        Exit;
      FileHandle := AX;
    end;
    AllocateSwapFile := True;
  end;

  function GetDiskClass(Drive : Char; var SubstDriveChar : Char) : DiskClass;
    {-Return the disk class for the drive with the specified letter}
    {-This routine uses an undocumented DOS function ($32). Information about
      this function was obtained from Terry Dettmann's DOS Programmer's
      Reference (Que, 1988).}
  type
    ParamBlock =
      record
        DriveNumber, DeviceDriverUnit : Byte;
        BytesPerSector : Word;
        SectorsPerCluster, ShiftFactor : Byte;
        ReservedBootSectors : Word;
        FatCopies : Byte;
        RootDirEntries, FirstDataSector, HighestCluster : Word;
        SectorsPerFat : Byte;
        RootDirStartingSector : Word;
        DeviceDriverAddress : Pointer;
        Media2and3 : Byte;        {media descriptor here in DOS 2.x and 3.x}
        Media4 : Byte;            {media descriptor here in DOS 4.x}
        NextDeviceParamBlock : Pointer;
      end;
    ParamBlockPtr = ^ParamBlock;
  var
    DriveNum : Byte;
    MediaDescriptor : Byte;
    Regs : Registers;
  begin
    {assume failure}
    GetDiskClass := InvalidDrive;

    {assume that this is not a SUBSTituted drive}
    SubstDriveChar := Drive;

    {convert drive letter to drive number}
    Drive := Upcase(Drive);
    case Drive of
      'A'..'Z' : DriveNum := Ord(Drive)-$40;
    else Exit;
    end;

    with Regs do begin
      {get pointer to media descriptor byte}
      AH := $1C;
      DL := DriveNum;
      MSDOS(Regs);
      MediaDescriptor := Mem[DS:BX];

      {get pointer to drive parameter block}
      AH := $32;
      DL := DriveNum;
      MSDOS(Regs);

      {drive invalid if AL = $FF}
      if (AL = $FF) then
        Exit;

      with ParamBlockPtr(Ptr(DS, BX))^ do begin
        {check for SUBSTituted drive}
        if (DriveNumber <> Pred(DriveNum)) then begin
          GetDiskClass := SubstDrive;
          SubstDriveChar := Char(Ord('A')+DriveNumber);
        end
        else if (FatCopies = 1) then
          {RAM disks have one copy of File Allocation Table}
          GetDiskClass := RamDisk
        else if (MediaDescriptor = $F8) then
          {MediaDescriptor of $F8 indicates hard disk}
          GetDiskClass := HardDisk
        else if (MediaDescriptor = $FD) and (SectorsPerFat <> 2) then
          {Bernoulli drives have more than 2 sectors per FAT}
          GetDiskClass := Bernoulli
        else if (MediaDescriptor >= $F9) then
          {media descriptors >= $F9 are for floppy disks}
          case HighestCluster of
            355 : GetDiskClass := Floppy360;
            714,
            1423 : GetDiskClass := Floppy720;
            2372 : GetDiskClass := Floppy12;
          else GetDiskClass := OtherFloppy;
          end
        else if (MediaDescriptor = $F0) and (HighestCluster = 2848) then
          {it's a 1.44 meg floppy}
          GetDiskClass := Floppy144
        else
          {unable to classify disk/drive}
          GetDiskClass := UnknownDisk;
      end;
    end;
  end;

  function IsRemovable(DriveChar : Char) : Boolean;
    {-Return true if specified drive has removable media}
  var
    Class : DiskClass;
    SubstChar : Char;
  begin
    repeat
      Class := GetDiskClass(DriveChar, SubstChar);
      DriveChar := SubstChar;
    until Class <> SubstDrive;
    case Class of
      Floppy360..OtherFloppy : IsRemovable := True;
    else
      {Note: Bernoulli and Unknown drive types treated as non-removable}
      IsRemovable := False;
    end;
  end;

  function DefaultDrive : Char;
    {-Return default drive letter}
  inline(
    $B4/$19/                      {mov ah,$19}
    $CD/$21/                      {int $21}
    $04/$41);                     {add al,$41}

  function PrepareExecWithSwap(LastToSave : Pointer;
                               SwapFileName : String) : Boolean;
    {-Set up for a shell with swapping, returning true if successful}
  var
    PagesInEms : Word;
    DriveChar : Char;
  begin
    PrepareExecWithSwap := False;
    if EmsAllocated or SwapFileAllocated then
      Exit;
    NoOfBytesSwapped := PtrDiff(LastToSave, @FirstToSave);
    if NoOfBytesSwapped <= 0 then
      Exit;
    if EmsInstalled then begin
      PagesInEms := Pred(NoOfBytesSwapped+EmsPageSize) div EmsPageSize;
      EmsHandle := AllocateEmsPages(PagesInEms);
      if EmsHandle <> $FFFF then begin
        EmsAllocated := True;
        FrameSeg := EmsPageFrame;
        if FrameSeg <> 0 then begin
          PrepareExecWithSwap := True;
          Exit;
        end;
      end;
    end;

    if Length(SwapFileName) <> 0 then begin
      SwapName := SwapFileName+#0;
      if Pos(':', SwapFileName) = 2 then
        {Drive letter specified for swap file}
        DriveChar := Upcase(SwapFileName[1])
      else
        {Swap file on default drive}
        DriveChar := DefaultDrive;
      SwapFileAllocated := (not IsRemovable(DriveChar) and
                            (DiskFree(Ord(DriveChar)-$40) > NoOfBytesSwapped) and
                            AllocateSwapFile(SwapFileHandle));
      if SwapFileAllocated then
        PrepareExecWithSwap := True;
    end;
  end;

  {$F+}
  procedure ExecWithSwapExit;
  begin
    ExitProc := SaveExit;
    RemoveExecWithSwap;
  end;
  {$F-}

begin
  EmsAllocated := False;
  SwapFileAllocated := False;
  NoOfBytesSwapped := 0;
{  SaveExit := ExitProc;
  ExitProc := @ExecWithSwapExit;}
end.
