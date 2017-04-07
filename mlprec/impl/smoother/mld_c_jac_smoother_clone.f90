!  
!   
!                             MLD2P4  version 2.1
!    MultiLevel Domain Decomposition Parallel Preconditioners Package
!               based on PSBLAS (Parallel Sparse BLAS version 3.4)
!    
!    (C) Copyright 2008, 2010, 2012, 2015, 2017 
!  
!        Salvatore Filippone    Cranfield University
!        Ambra Abdullahi Hassan University of Rome Tor Vergata
!        Alfredo Buttari        CNRS-IRIT, Toulouse
!        Pasqua D'Ambra         ICAR-CNR, Naples
!        Daniela di Serafino    University of Campania "L. Vanvitelli", Caserta
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
subroutine mld_c_jac_smoother_clone(sm,smout,info)
  
  use psb_base_mod
  use mld_c_jac_smoother, mld_protect_name => mld_c_jac_smoother_clone

  Implicit None

  ! Arguments
  class(mld_c_jac_smoother_type), intent(inout)               :: sm
  class(mld_c_base_smoother_type), allocatable, intent(inout) :: smout
  integer(psb_ipk_), intent(out)                :: info
  ! Local variables
  integer(psb_ipk_) :: err_act


  info=psb_success_
  call psb_erractionsave(err_act)

  if (allocated(smout)) then
    call smout%free(info)
    if (info == psb_success_) deallocate(smout, stat=info)
  end if
  if (info == psb_success_) &
       & allocate(mld_c_jac_smoother_type :: smout, stat=info)
  if (info /= 0) then 
    info = psb_err_alloc_dealloc_
    goto 9999 
  end if

  select type(smo => smout)
  type is (mld_c_jac_smoother_type)
    smo%nnz_nd_tot = sm%nnz_nd_tot
    call sm%nd%clone(smo%nd,info)
    if ((info==psb_success_).and.(allocated(sm%sv))) then
      allocate(smout%sv,mold=sm%sv,stat=info)
      if (info == psb_success_) call sm%sv%clone(smo%sv,info)
    end if

  class default
    info = psb_err_internal_error_
  end select

  if (info /= 0) goto 9999

  call psb_erractionrestore(err_act)
  return

9999 call psb_error_handler(err_act)

  return
end subroutine mld_c_jac_smoother_clone
