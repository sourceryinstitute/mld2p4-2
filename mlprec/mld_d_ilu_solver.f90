!  
!   
!                             MLD2P4  version 2.1
!    MultiLevel Domain Decomposition Parallel Preconditioners Package
!               based on PSBLAS (Parallel Sparse BLAS version 3.5)
!    
!    (C) Copyright 2008, 2010, 2012, 2015, 2017 
!  
!        Salvatore Filippone    Cranfield University, UK
!        Pasqua D'Ambra         IAC-CNR, Naples, IT
!        Daniela di Serafino    University of Campania "L. Vanvitelli", Caserta, IT
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
!
!
! File: mld_d_ilu_solver_mod.f90
!
! Module: mld_d_ilu_solver_mod
!
!  This module defines: 
!  - the mld_d_ilu_solver_type data structure containing the ingredients
!    for a local Incomplete LU factorization.
!    1. The factorization is always restricted to the diagonal block of the
!       current image (coherently with the definition of a SOLVER as a local
!       object)
!    2. The code provides support for both pattern-based ILU(K) and
!       threshold base ILU(T,L)
!    3. The diagonal is stored separately, so strictly speaking this is
!       an incomplete LDU factorization; 
!    4. The application phase is shared;
!
!
module mld_d_ilu_solver

  use mld_base_prec_type, only : mld_fact_names
  use mld_d_base_solver_mod
  use mld_d_ilu_fact_mod

  type, extends(mld_d_base_solver_type) :: mld_d_ilu_solver_type
    type(psb_dspmat_type)      :: l, u
    real(psb_dpk_), allocatable :: d(:)
    type(psb_d_vect_type)      :: dv
    integer(psb_ipk_)            :: fact_type, fill_in
    real(psb_dpk_)                :: thresh
  contains
    procedure, pass(sv) :: dump    => mld_d_ilu_solver_dmp
    procedure, pass(sv) :: ccheck  => d_ilu_solver_check
    procedure, pass(sv) :: clone   => mld_d_ilu_solver_clone
    procedure, pass(sv) :: build   => mld_d_ilu_solver_bld
    procedure, pass(sv) :: cnv     => mld_d_ilu_solver_cnv
    procedure, pass(sv) :: apply_v => mld_d_ilu_solver_apply_vect
    procedure, pass(sv) :: apply_a => mld_d_ilu_solver_apply
    procedure, pass(sv) :: free    => d_ilu_solver_free
    procedure, pass(sv) :: seti    => d_ilu_solver_seti
    procedure, pass(sv) :: setc    => d_ilu_solver_setc
    procedure, pass(sv) :: setr    => d_ilu_solver_setr
    procedure, pass(sv) :: cseti   => d_ilu_solver_cseti
    procedure, pass(sv) :: csetc   => d_ilu_solver_csetc
    procedure, pass(sv) :: csetr   => d_ilu_solver_csetr
    procedure, pass(sv) :: descr   => d_ilu_solver_descr
    procedure, pass(sv) :: default => d_ilu_solver_default
    procedure, pass(sv) :: sizeof  => d_ilu_solver_sizeof
    procedure, pass(sv) :: get_nzeros => d_ilu_solver_get_nzeros
    procedure, nopass   :: get_wrksz => d_ilu_solver_get_wrksize
    procedure, nopass   :: get_fmt    => d_ilu_solver_get_fmt
    procedure, nopass   :: get_id     => d_ilu_solver_get_id
  end type mld_d_ilu_solver_type


  private :: d_ilu_solver_bld, d_ilu_solver_apply, &
       &  d_ilu_solver_free,   d_ilu_solver_seti, &
       &  d_ilu_solver_setc,   d_ilu_solver_setr,&
       &  d_ilu_solver_descr,  d_ilu_solver_sizeof, &
       &  d_ilu_solver_default, d_ilu_solver_dmp, &
       &  d_ilu_solver_apply_vect, d_ilu_solver_get_nzeros, &
       &  d_ilu_solver_get_fmt, d_ilu_solver_check, &
       &  d_ilu_solver_get_id, d_ilu_solver_get_wrksize


  interface 
    subroutine mld_d_ilu_solver_apply_vect(alpha,sv,x,beta,y,desc_data,&
         & trans,work,wv,info,init,initu)
      import :: psb_desc_type, mld_d_ilu_solver_type, psb_d_vect_type, psb_dpk_, &
           & psb_dspmat_type, psb_d_base_sparse_mat, psb_d_base_vect_type, psb_ipk_
      implicit none 
      type(psb_desc_type), intent(in)             :: desc_data
      class(mld_d_ilu_solver_type), intent(inout) :: sv
      type(psb_d_vect_type),intent(inout)         :: x
      type(psb_d_vect_type),intent(inout)         :: y
      real(psb_dpk_),intent(in)                    :: alpha,beta
      character(len=1),intent(in)                   :: trans
      real(psb_dpk_),target, intent(inout)         :: work(:)
      type(psb_d_vect_type),intent(inout)         :: wv(:)
      integer(psb_ipk_), intent(out)                :: info
      character, intent(in), optional                :: init
      type(psb_d_vect_type),intent(inout), optional   :: initu
    end subroutine mld_d_ilu_solver_apply_vect
  end interface

  interface 
    subroutine mld_d_ilu_solver_apply(alpha,sv,x,beta,y,desc_data,&
         & trans,work,info,init,initu)
      import :: psb_desc_type, mld_d_ilu_solver_type, psb_d_vect_type, psb_dpk_, &
           & psb_dspmat_type, psb_d_base_sparse_mat, psb_d_base_vect_type, psb_ipk_
      implicit none 
      type(psb_desc_type), intent(in)      :: desc_data
      class(mld_d_ilu_solver_type), intent(inout) :: sv
      real(psb_dpk_),intent(inout)         :: x(:)
      real(psb_dpk_),intent(inout)         :: y(:)
      real(psb_dpk_),intent(in)            :: alpha,beta
      character(len=1),intent(in)           :: trans
      real(psb_dpk_),target, intent(inout) :: work(:)
      integer(psb_ipk_), intent(out)        :: info
      character, intent(in), optional       :: init
      real(psb_dpk_),intent(inout), optional :: initu(:)
    end subroutine mld_d_ilu_solver_apply
  end interface

  interface 
    subroutine mld_d_ilu_solver_bld(a,desc_a,sv,info,b,amold,vmold,imold)
      import :: psb_desc_type, mld_d_ilu_solver_type, psb_d_vect_type, psb_dpk_, &
           & psb_dspmat_type, psb_d_base_sparse_mat, psb_d_base_vect_type,&
           & psb_ipk_, psb_i_base_vect_type
      implicit none 
      type(psb_dspmat_type), intent(in), target           :: a
      Type(psb_desc_type), Intent(in)                     :: desc_a 
      class(mld_d_ilu_solver_type), intent(inout)         :: sv
      integer(psb_ipk_), intent(out)                      :: info
      type(psb_dspmat_type), intent(in), target, optional :: b
      class(psb_d_base_sparse_mat), intent(in), optional  :: amold
      class(psb_d_base_vect_type), intent(in), optional   :: vmold
      class(psb_i_base_vect_type), intent(in), optional   :: imold
    end subroutine mld_d_ilu_solver_bld
  end interface

  interface 
    subroutine mld_d_ilu_solver_cnv(sv,info,amold,vmold,imold)
      import :: mld_d_ilu_solver_type, psb_dpk_, &
           & psb_d_base_sparse_mat, psb_d_base_vect_type,&
           & psb_ipk_, psb_i_base_vect_type
      implicit none 
      class(mld_d_ilu_solver_type), intent(inout)         :: sv
      integer(psb_ipk_), intent(out)                      :: info
      class(psb_d_base_sparse_mat), intent(in), optional  :: amold
      class(psb_d_base_vect_type), intent(in), optional   :: vmold
      class(psb_i_base_vect_type), intent(in), optional   :: imold
    end subroutine mld_d_ilu_solver_cnv
  end interface
  
  interface 
    subroutine mld_d_ilu_solver_dmp(sv,ictxt,level,info,prefix,head,solver)
      import :: psb_desc_type, mld_d_ilu_solver_type, psb_d_vect_type, psb_dpk_, &
           & psb_dspmat_type, psb_d_base_sparse_mat, psb_d_base_vect_type, &
           & psb_ipk_
      implicit none 
      class(mld_d_ilu_solver_type), intent(in) :: sv
      integer(psb_ipk_), intent(in)              :: ictxt
      integer(psb_ipk_), intent(in)              :: level
      integer(psb_ipk_), intent(out)             :: info
      character(len=*), intent(in), optional     :: prefix, head
      logical, optional, intent(in)              :: solver
    end subroutine mld_d_ilu_solver_dmp
  end interface
  
  interface
    subroutine mld_d_ilu_solver_clone(sv,svout,info)
      import :: psb_desc_type, psb_dspmat_type,  psb_d_base_sparse_mat, &
           & psb_d_vect_type, psb_d_base_vect_type, psb_dpk_, &
           & mld_d_base_solver_type, mld_d_ilu_solver_type, psb_ipk_
      Implicit None
      
      ! Arguments
      class(mld_d_ilu_solver_type), intent(inout)               :: sv
      class(mld_d_base_solver_type), allocatable, intent(inout) :: svout
      integer(psb_ipk_), intent(out)              :: info
    end subroutine mld_d_ilu_solver_clone
  end interface

contains

  subroutine d_ilu_solver_default(sv)

    Implicit None

    ! Arguments
    class(mld_d_ilu_solver_type), intent(inout) :: sv

    sv%fact_type = mld_ilu_n_
    sv%fill_in   = 0
    sv%thresh    = dzero

    return
  end subroutine d_ilu_solver_default

  subroutine d_ilu_solver_check(sv,info)

    Implicit None

    ! Arguments
    class(mld_d_ilu_solver_type), intent(inout) :: sv
    integer(psb_ipk_), intent(out)                :: info
    integer(psb_ipk_) :: err_act
    character(len=20) :: name='d_ilu_solver_check'

    call psb_erractionsave(err_act)
    info = psb_success_

    call mld_check_def(sv%fact_type,&
         & 'Factorization',mld_ilu_n_,is_legal_ilu_fact)

    select case(sv%fact_type)
    case(mld_ilu_n_,mld_milu_n_)      
      call mld_check_def(sv%fill_in,&
           & 'Level',izero,is_int_non_negative)
    case(mld_ilu_t_)                 
      call mld_check_def(sv%thresh,&
           & 'Eps',dzero,is_legal_d_fact_thrs)
    end select
    
    if (info /= psb_success_) goto 9999
    
    call psb_erractionrestore(err_act)
    return

9999 call psb_error_handler(err_act)
    return

  end subroutine d_ilu_solver_check


  subroutine d_ilu_solver_seti(sv,what,val,info)

    Implicit None

    ! Arguments
    class(mld_d_ilu_solver_type), intent(inout) :: sv 
    integer(psb_ipk_), intent(in)                 :: what 
    integer(psb_ipk_), intent(in)                 :: val
    integer(psb_ipk_), intent(out)                :: info
    integer(psb_ipk_)  :: err_act
    character(len=20)  :: name='d_ilu_solver_seti'

    info = psb_success_
    call psb_erractionsave(err_act)

    select case(what) 
    case(mld_sub_solve_) 
      sv%fact_type = val
    case(mld_sub_fillin_)
      sv%fill_in   = val
    case default
      call sv%mld_d_base_solver_type%set(what,val,info)
    end select

    call psb_erractionrestore(err_act)
    return

9999 call psb_error_handler(err_act)
    return
  end subroutine d_ilu_solver_seti

  subroutine d_ilu_solver_setc(sv,what,val,info)

    Implicit None

    ! Arguments
    class(mld_d_ilu_solver_type), intent(inout) :: sv
    integer(psb_ipk_), intent(in)                 :: what 
    character(len=*), intent(in)                  :: val
    integer(psb_ipk_), intent(out)                :: info
    integer(psb_ipk_)  :: err_act, ival
    character(len=20)  :: name='d_ilu_solver_setc'

    info = psb_success_
    call psb_erractionsave(err_act)


    ival =  sv%stringval(val)
    if (ival >= 0) then 
      call sv%set(what,ival,info)
    end if
      
    if (info /= psb_success_) then
      info = psb_err_from_subroutine_
      call psb_errpush(info, name)
      goto 9999
    end if

    call psb_erractionrestore(err_act)
    return

9999 call psb_error_handler(err_act)
    return
  end subroutine d_ilu_solver_setc
  
  subroutine d_ilu_solver_setr(sv,what,val,info)

    Implicit None

    ! Arguments
    class(mld_d_ilu_solver_type), intent(inout) :: sv 
    integer(psb_ipk_), intent(in)                 :: what 
    real(psb_dpk_), intent(in)                     :: val
    integer(psb_ipk_), intent(out)                :: info
    integer(psb_ipk_)  :: err_act
    character(len=20)  :: name='d_ilu_solver_setr'

    call psb_erractionsave(err_act)
    info = psb_success_

    select case(what)
    case(mld_sub_iluthrs_) 
      sv%thresh = val
    case default
      call sv%mld_d_base_solver_type%set(what,val,info)
    end select

    call psb_erractionrestore(err_act)
    return

9999 call psb_error_handler(err_act)
    return
  end subroutine d_ilu_solver_setr

  subroutine d_ilu_solver_cseti(sv,what,val,info)

    Implicit None

    ! Arguments
    class(mld_d_ilu_solver_type), intent(inout) :: sv 
    character(len=*), intent(in)                  :: what 
    integer(psb_ipk_), intent(in)                 :: val
    integer(psb_ipk_), intent(out)                :: info
    integer(psb_ipk_)  :: err_act
    character(len=20)  :: name='d_ilu_solver_cseti'

    info = psb_success_
    call psb_erractionsave(err_act)

    select case(psb_toupper(what))
    case('SUB_SOLVE') 
      sv%fact_type = val
    case('SUB_FILLIN')
      sv%fill_in   = val
    case default
      call sv%mld_d_base_solver_type%set(what,val,info)
    end select

    call psb_erractionrestore(err_act)
    return

9999 call psb_error_handler(err_act)
    return
  end subroutine d_ilu_solver_cseti

  subroutine d_ilu_solver_csetc(sv,what,val,info)

    Implicit None

    ! Arguments
    class(mld_d_ilu_solver_type), intent(inout) :: sv
    character(len=*), intent(in)                  :: what 
    character(len=*), intent(in)                  :: val
    integer(psb_ipk_), intent(out)                :: info
    integer(psb_ipk_)  :: err_act, ival
    character(len=20)  :: name='d_ilu_solver_csetc'

    info = psb_success_
    call psb_erractionsave(err_act)


    ival =  sv%stringval(val)
    if (ival >= 0) then 
      call sv%set(what,ival,info)
    end if
      
    if (info /= psb_success_) then
      info = psb_err_from_subroutine_
      call psb_errpush(info, name)
      goto 9999
    end if

    call psb_erractionrestore(err_act)
    return

9999 call psb_error_handler(err_act)
    return
  end subroutine d_ilu_solver_csetc
  
  subroutine d_ilu_solver_csetr(sv,what,val,info)

    Implicit None

    ! Arguments
    class(mld_d_ilu_solver_type), intent(inout) :: sv 
    character(len=*), intent(in)                  :: what 
    real(psb_dpk_), intent(in)                     :: val
    integer(psb_ipk_), intent(out)                :: info
    integer(psb_ipk_)  :: err_act
    character(len=20)  :: name='d_ilu_solver_csetr'

    call psb_erractionsave(err_act)
    info = psb_success_

    select case(psb_toupper(what))
    case('SUB_ILUTHRS') 
      sv%thresh = val
    case default
      call sv%mld_d_base_solver_type%set(what,val,info)
    end select

    call psb_erractionrestore(err_act)
    return

9999 call psb_error_handler(err_act)
    return
  end subroutine d_ilu_solver_csetr

  subroutine d_ilu_solver_free(sv,info)

    Implicit None

    ! Arguments
    class(mld_d_ilu_solver_type), intent(inout) :: sv
    integer(psb_ipk_), intent(out)                :: info
    integer(psb_ipk_)  :: err_act
    character(len=20)  :: name='d_ilu_solver_free'

    call psb_erractionsave(err_act)
    info = psb_success_

    if (allocated(sv%d)) then 
      deallocate(sv%d,stat=info)
      if (info /= psb_success_) then 
        info = psb_err_alloc_dealloc_
        call psb_errpush(info,name)
        goto 9999 
      end if
    end if
    call sv%l%free()
    call sv%u%free()
    call sv%dv%free(info)

    call psb_erractionrestore(err_act)
    return

9999 call psb_error_handler(err_act)
    return
  end subroutine d_ilu_solver_free

  subroutine d_ilu_solver_descr(sv,info,iout,coarse)

    Implicit None

    ! Arguments
    class(mld_d_ilu_solver_type), intent(in) :: sv
    integer(psb_ipk_), intent(out)             :: info
    integer(psb_ipk_), intent(in), optional    :: iout
    logical, intent(in), optional       :: coarse

    ! Local variables
    integer(psb_ipk_)      :: err_act
    character(len=20), parameter :: name='mld_d_ilu_solver_descr'
    integer(psb_ipk_) :: iout_

    call psb_erractionsave(err_act)
    info = psb_success_
    if (present(iout)) then 
      iout_ = iout 
    else
      iout_ = psb_out_unit
    endif

    write(iout_,*) '  Incomplete factorization solver: ',&
         &  mld_fact_names(sv%fact_type)
    select case(sv%fact_type)
    case(mld_ilu_n_,mld_milu_n_)      
      write(iout_,*) '  Fill level:',sv%fill_in
    case(mld_ilu_t_)         
      write(iout_,*) '  Fill level:',sv%fill_in
      write(iout_,*) '  Fill threshold :',sv%thresh
    end select

    call psb_erractionrestore(err_act)
    return

9999 call psb_error_handler(err_act)
    return
  end subroutine d_ilu_solver_descr

  function d_ilu_solver_get_nzeros(sv) result(val)

    implicit none 
    ! Arguments
    class(mld_d_ilu_solver_type), intent(in) :: sv
    integer(psb_long_int_k_) :: val
    integer(psb_ipk_)        :: i
    
    val = 0 
    val = val + sv%dv%get_nrows()
    val = val + sv%l%get_nzeros()
    val = val + sv%u%get_nzeros()

    return
  end function d_ilu_solver_get_nzeros

  function d_ilu_solver_sizeof(sv) result(val)

    implicit none 
    ! Arguments
    class(mld_d_ilu_solver_type), intent(in) :: sv
    integer(psb_long_int_k_) :: val
    integer(psb_ipk_)        :: i

    val = 2*psb_sizeof_int + psb_sizeof_dp
    val = val + sv%dv%sizeof()
    val = val + sv%l%sizeof()
    val = val + sv%u%sizeof()

    return
  end function d_ilu_solver_sizeof

  function d_ilu_solver_get_fmt() result(val)
    implicit none 
    character(len=32)  :: val

    val = "ILU solver"
  end function d_ilu_solver_get_fmt

  function d_ilu_solver_get_id() result(val)
    implicit none 
    integer(psb_ipk_)  :: val
    
    val = mld_ilu_n_
  end function d_ilu_solver_get_id

  function d_ilu_solver_get_wrksize() result(val)
    implicit none 
    integer(psb_ipk_)  :: val

    val = 2
  end function d_ilu_solver_get_wrksize
  
end module mld_d_ilu_solver
