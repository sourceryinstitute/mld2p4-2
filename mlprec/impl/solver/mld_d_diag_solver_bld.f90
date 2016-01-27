!!$
!!$ 
!!$                           MLD2P4  version 2.0
!!$  MultiLevel Domain Decomposition Parallel Preconditioners Package
!!$             based on PSBLAS (Parallel Sparse BLAS version 3.3)
!!$  
!!$  (C) Copyright 2008, 2010, 2012, 2015
!!$
!!$                      Salvatore Filippone  University of Rome Tor Vergata
!!$                      Alfredo Buttari      CNRS-IRIT, Toulouse
!!$                      Pasqua D'Ambra       ICAR-CNR, Naples
!!$                      Daniela di Serafino  Second University of Naples
!!$ 
!!$  Redistribution and use in source and binary forms, with or without
!!$  modification, are permitted provided that the following conditions
!!$  are met:
!!$    1. Redistributions of source code must retain the above copyright
!!$       notice, this list of conditions and the following disclaimer.
!!$    2. Redistributions in binary form must reproduce the above copyright
!!$       notice, this list of conditions, and the following disclaimer in the
!!$       documentation and/or other materials provided with the distribution.
!!$    3. The name of the MLD2P4 group or the names of its contributors may
!!$       not be used to endorse or promote products derived from this
!!$       software without specific written permission.
!!$ 
!!$  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
!!$  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
!!$  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
!!$  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE MLD2P4 GROUP OR ITS CONTRIBUTORS
!!$  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
!!$  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
!!$  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
!!$  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
!!$  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
!!$  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
!!$  POSSIBILITY OF SUCH DAMAGE.
!!$ 
!!$
subroutine mld_d_diag_solver_bld(a,desc_a,sv,upd,info,b,amold,vmold,imold)
  
  use psb_base_mod
  use mld_d_diag_solver, mld_protect_name => mld_d_diag_solver_bld

  Implicit None

  ! Arguments
  type(psb_dspmat_type), intent(in), target           :: a
  Type(psb_desc_type), Intent(in)                     :: desc_a 
  class(mld_d_diag_solver_type), intent(inout)        :: sv
  character, intent(in)                               :: upd
  integer(psb_ipk_), intent(out)                      :: info
  type(psb_dspmat_type), intent(in), target, optional :: b
  class(psb_d_base_sparse_mat), intent(in), optional  :: amold
  class(psb_d_base_vect_type), intent(in), optional   :: vmold
  class(psb_i_base_vect_type), intent(in), optional   :: imold
  ! Local variables
  integer(psb_ipk_) :: n_row,n_col, nrow_a, nztota
  real(psb_dpk_), pointer :: ww(:), aux(:), tx(:),ty(:)
  real(psb_dpk_), allocatable :: tdb(:)
  integer(psb_ipk_) :: ictxt,np,me,i, err_act, debug_unit, debug_level
  character(len=20) :: name='d_diag_solver_bld', ch_err

  info=psb_success_
  call psb_erractionsave(err_act)
  debug_unit  = psb_get_debug_unit()
  debug_level = psb_get_debug_level()
  ictxt       = desc_a%get_context()
  call psb_info(ictxt, me, np)
  if (debug_level >= psb_debug_outer_) &
       & write(debug_unit,*) me,' ',trim(name),' start'


  n_row  = desc_a%get_local_rows()
  nrow_a = a%get_nrows()

  sv%d = a%get_diag(info)
  if (info == psb_success_) call psb_realloc(n_row,sv%d,info)
  if (present(b)) then 
    tdb=b%get_diag(info)
    if (size(tdb)+nrow_a > n_row) call psb_realloc(nrow_a+size(tdb),sv%d,info)
    if (info == psb_success_) sv%d(nrow_a+1:nrow_a+size(tdb)) = tdb(:)
  end if
  if (info /= psb_success_) then 
    call psb_errpush(psb_err_from_subroutine_,name,a_err='get_diag')
    goto 9999      
  end if

  do i=1,n_row
    if (sv%d(i) == dzero) then 
      sv%d(i) = done
    else
      sv%d(i) = done/sv%d(i)
    end if
  end do
  allocate(sv%dv,stat=info) 
  if (info == psb_success_) then 
    if (present(vmold)) then 
      allocate(sv%dv%v,mold=vmold,stat=info) 
    else
      allocate(psb_d_base_vect_type :: sv%dv%v,stat=info) 
    end if
  end if
  if (info == psb_success_) then 
    call sv%dv%bld(sv%d)
  else
    call psb_errpush(psb_err_from_subroutine_,name,& 
         & a_err='Allocate sv%dv')
    goto 9999      
  end if

  if (debug_level >= psb_debug_outer_) &
       & write(debug_unit,*) me,' ',trim(name),' end'

  call psb_erractionrestore(err_act)
  return

9999 call psb_error_handler(err_act)

  return
end subroutine mld_d_diag_solver_bld
