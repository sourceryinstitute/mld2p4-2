!!$
!!$ 
!!$                           MLD2P4  version 2.1
!!$  MultiLevel Domain Decomposition Parallel Preconditioners Package
!!$             based on PSBLAS (Parallel Sparse BLAS version 3.3)
!!$  
!!$  (C) Copyright 2008, 2010, 2012, 2015, 2017 
!!$
!!$                      Salvatore Filippone  Cranfield University
!!$		      Ambra Abdullahi Hassan University of Rome Tor Vergata
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
subroutine mld_d_base_smoother_apply_vect(alpha,sm,x,beta,y,desc_data,&
     &  trans,sweeps,work,info,init,initu)
  use psb_base_mod
  use mld_d_base_smoother_mod, mld_protect_name =>  mld_d_base_smoother_apply_vect
  implicit none 
  type(psb_desc_type), intent(in)                 :: desc_data
  class(mld_d_base_smoother_type), intent(inout) :: sm
  type(psb_d_vect_type),intent(inout)            :: x
  type(psb_d_vect_type),intent(inout)            :: y
  real(psb_dpk_),intent(in)                       :: alpha,beta
  character(len=1),intent(in)                      :: trans
  integer(psb_ipk_), intent(in)                    :: sweeps
  real(psb_dpk_),target, intent(inout)            :: work(:)
  integer(psb_ipk_), intent(out)                   :: info
  character, intent(in), optional                  :: init
  type(psb_d_vect_type),intent(inout), optional   :: initu

  integer(psb_ipk_) :: err_act
  character(len=20) :: name='d_base_smoother_apply'

  call psb_erractionsave(err_act)
  info = psb_success_
  if (sweeps == 0) then
    
    !
    ! K^0 = I
    ! zero sweeps  of any smoother is just the identity.
    !
    call psb_geaxpby(alpha,x,beta,y,desc_data,info) 

  else
    if (allocated(sm%sv)) then
      call sm%sv%apply(alpha,x,beta,y,desc_data,trans,work,info,init=init, initu=initu)
    else
      info = 1121
    endif
  end if
  if (info /= psb_success_) then 
    call psb_errpush(info,name)
    goto 9999 
  end if

  call psb_erractionrestore(err_act)
  return

9999 call psb_error_handler(err_act)

  return

end subroutine mld_d_base_smoother_apply_vect
