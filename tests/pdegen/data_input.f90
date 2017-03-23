!   
!   
!                             MLD2P4  version 2.0
!    MultiLevel Domain Decomposition Parallel Preconditioners Package
!               based on PSBLAS (Parallel Sparse BLAS version 3.3)
!    
!    (C) Copyright 2008, 2010, 2012, 2015
!  
!                        Salvatore Filippone  University of Rome Tor Vergata
!                        Alfredo Buttari      CNRS-IRIT, Toulouse
!                        Pasqua D'Ambra       ICAR-CNR, Naples
!                        Daniela di Serafino  Second University of Naples
!   
!    Redistribution and use in source and binary forms, with or without
!    modification, are permitted provided that the following conditions
!    are met:
!      1. Redistributions of source code must retain the above copyright
!         notice, this list of conditions and the following disclaimer.
!      2. Redistributions in binary form must reproduce the above copyright
!         notice, this list of conditions, and the following disclaimer in the
!         documentation and/or other materials provided with the distribution.
!      3. The name of the MLD2P4 group or the names of its contributors may
!         not be used to endorse or promote products derived from this
!         software without specific written permission.
!   
!    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
!    ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
!    TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
!    PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE MLD2P4 GROUP OR ITS CONTRIBUTORS
!    BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
!    CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
!    SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
!    INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
!    CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
!    ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
!    POSSIBILITY OF SUCH DAMAGE.
!   
!  
module data_input
  use psb_base_mod, only : psb_spk_, psb_dpk_, psb_ipk_
  
  interface read_data
    module procedure read_char, read_int,&
         & read_double, read_single, read_logical,&
         & string_read_char, string_read_int,&
         & string_read_double, string_read_single, &
         & string_read_logical
  end interface read_data
  interface trim_string
    module procedure trim_string
  end interface

  character(len=4096), private  :: charbuf
  character, private, parameter :: def_marker="!"

contains

  subroutine read_logical(val,file,marker)
    logical, intent(out) :: val
    integer(psb_ipk_), intent(in)          :: file
    character(len=1), optional, intent(in) :: marker

    read(file,'(a)')charbuf
    call read_data(val,charbuf,marker)

  end subroutine read_logical

  subroutine read_char(val,file,marker)
    character(len=*), intent(out) :: val
    integer(psb_ipk_), intent(in)           :: file
    character(len=1), optional, intent(in) :: marker

    read(file,'(a)')charbuf
    call read_data(val,charbuf,marker)

  end subroutine read_char

  subroutine read_int(val,file,marker)
    integer(psb_ipk_), intent(out) :: val
    integer(psb_ipk_), intent(in)  :: file
    character(len=1), optional, intent(in) :: marker

    read(file,'(a)')charbuf
    call read_data(val,charbuf,marker)

  end subroutine read_int
  subroutine read_single(val,file,marker)
    real(psb_spk_), intent(out) :: val
    integer(psb_ipk_), intent(in)         :: file
    character(len=1), optional, intent(in) :: marker

    read(file,'(a)')charbuf
    call read_data(val,charbuf,marker)

  end subroutine read_single
  subroutine read_double(val,file,marker)
    real(psb_dpk_), intent(out) :: val
    integer(psb_ipk_), intent(in)         :: file
    character(len=1), optional, intent(in) :: marker

    read(file,'(a)')charbuf
    call read_data(val,charbuf,marker)

  end subroutine read_double

  subroutine string_read_char(val,file,marker)
    character(len=*), intent(out) :: val
    character(len=*), intent(in)  :: file
    character(len=1), optional, intent(in) :: marker
    character(len=1)    :: marker_
    character(len=1024) :: charbuf
    integer(psb_ipk_) :: idx
    if (present(marker)) then 
      marker_ = marker
    else
      marker_ = def_marker
    end if
    read(file,'(a)')charbuf
    charbuf = adjustl(charbuf)
    idx=index(charbuf,marker_)
    if (idx == 0) idx = len(charbuf)+1
    read(charbuf(1:idx-1),'(a)') val
  end subroutine string_read_char

  subroutine string_read_int(val,file,marker)
    integer(psb_ipk_), intent(out) :: val
    character(len=*), intent(in)  :: file
    character(len=1), optional, intent(in) :: marker
    character(len=1)    :: marker_
    character(len=1024) :: charbuf
    integer(psb_ipk_) :: idx
    if (present(marker)) then 
      marker_ = marker
    else
      marker_ = def_marker
    end if
    read(file,'(a)')charbuf
    charbuf = adjustl(charbuf)
    idx=index(charbuf,marker_)
    if (idx == 0) idx = len(charbuf)+1
    read(charbuf(1:idx-1),*) val
  end subroutine string_read_int

  subroutine string_read_single(val,file,marker)
    real(psb_spk_), intent(out) :: val
    character(len=*), intent(in)         :: file
    character(len=1), optional, intent(in) :: marker
    character(len=1)    :: marker_
    character(len=1024) :: charbuf
    integer(psb_ipk_) :: idx
    if (present(marker)) then 
      marker_ = marker
    else
      marker_ = def_marker
    end if
    read(file,'(a)')charbuf
    charbuf = adjustl(charbuf)
    idx=index(charbuf,marker_)
    if (idx == 0) idx = len(charbuf)+1
    read(charbuf(1:idx-1),*) val
  end subroutine string_read_single

  subroutine string_read_double(val,file,marker)
    real(psb_dpk_), intent(out) :: val
    character(len=*), intent(in)         :: file
    character(len=1), optional, intent(in) :: marker
    character(len=1)    :: marker_
    character(len=1024) :: charbuf
    integer(psb_ipk_) :: idx
    if (present(marker)) then 
      marker_ = marker
    else
      marker_ = def_marker
    end if
    read(file,'(a)')charbuf
    charbuf = adjustl(charbuf)
    idx=index(charbuf,marker_)
    if (idx == 0) idx = len(charbuf)+1
    read(charbuf(1:idx-1),*) val
  end subroutine string_read_double

  subroutine string_read_logical(val,file,marker)
    logical, intent(out) :: val
    character(len=*), intent(in)         :: file
    character(len=1), optional, intent(in) :: marker
    character(len=1)    :: marker_
    character(len=1024) :: charbuf
    integer(psb_ipk_) :: idx
    if (present(marker)) then 
      marker_ = marker
    else
      marker_ = def_marker
    end if
    read(file,'(a)')charbuf
    charbuf = adjustl(charbuf)
    idx=index(charbuf,marker_)
    if (idx == 0) idx = len(charbuf)+1
    read(charbuf(1:idx-1),*) val
  end subroutine string_read_logical

  function  trim_string(string,marker)
    character(len=*), intent(in) :: string
    character(len=1), optional, intent(in) :: marker
    character(len=len(string))    :: trim_string
    character(len=1)              :: marker_
    integer(psb_ipk_) :: idx
    if (present(marker)) then 
      marker_ = marker
    else
      marker_ = def_marker
    end if
    idx=index(string,marker_)
    trim_string = adjustl(string(idx:))
  end function trim_string
end module data_input

