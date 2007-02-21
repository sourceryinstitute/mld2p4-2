!!$ 
!!$ 
!!$                    MD2P4
!!$    Multilevel Domain Decomposition Parallel Preconditioner Package for PSBLAS
!!$                      for 
!!$              Parallel Sparse BLAS  v2.0
!!$    (C) Copyright 2006 Salvatore Filippone    University of Rome Tor Vergata
!!$                       Alfredo Buttari        University of Rome Tor Vergata
!!$                       Daniela di Serafino    Second University of Naples
!!$                       Pasqua D'Ambra         ICAR-CNR                      
!!$ 
!!$  Redistribution and use in source and binary forms, with or without
!!$  modification, are permitted provided that the following conditions
!!$  are met:
!!$    1. Redistributions of source code must retain the above copyright
!!$       notice, this list of conditions and the following disclaimer.
!!$    2. Redistributions in binary form must reproduce the above copyright
!!$       notice, this list of conditions, and the following disclaimer in the
!!$       documentation and/or other materials provided with the distribution.
!!$    3. The name of the MD2P4 group or the names of its contributors may
!!$       not be used to endorse or promote products derived from this
!!$       software without specific written permission.
!!$ 
!!$  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
!!$  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
!!$  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
!!$  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE MD2P4 GROUP OR ITS CONTRIBUTORS
!!$  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
!!$  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
!!$  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
!!$  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
!!$  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
!!$  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
!!$  POSSIBILITY OF SUCH DAMAGE.
!!$ 
!!$  
!*****************************************************************************
!*                                                                           *
!* This is where the action takes place.                                     *
!* ASMATBLD does the setup: building the prec descriptor plus retrieving     *
!*                           matrix rows if needed                           *
!*                                                                           *
!*                                                                           *
!*                                                                           *
!*                                                                           *
!* some open code does the renumbering                                       *
!*                                                                           *
!*                                                                           *
!*                                                                           *
!*                                                                           *
!*****************************************************************************
subroutine psb_zbjac_bld(a,desc_a,p,upd,info)
  use psb_base_mod
  use psb_prec_mod, mld_protect_name => psb_zbjac_bld

  implicit none
  !                                                                               
  !     .. Scalar Arguments ..                                                    
  integer, intent(out)                      :: info
  !     .. array Arguments ..                                                     
  type(psb_zspmat_type), intent(in), target :: a
  type(psb_zbaseprc_type), intent(inout)    :: p
  type(psb_desc_type), intent(in)           :: desc_a
  character, intent(in)                     :: upd

  !     .. Local Scalars ..                                                       
  integer  ::    i, j, jj, k, kk, m
  integer  ::    int_err(5)
  character ::        trans, unitd
  type(psb_zspmat_type) :: blck, atmp
  real(kind(1.d0)) :: t1,t2,t3,t4,t5,t6, t7, t8
  logical, parameter :: debugprt=.false., debug=.false., aggr_dump=.false.
  integer   nztota, nztotb, nztmp, nzl, nnr, ir, err_act,&
       & n_row, nrow_a,n_col, nhalo, ind, iind, i1,i2,ia
  integer :: ictxt,np,me
  character(len=20)      :: name, ch_err
  character(len=5), parameter :: coofmt='COO'

  if(psb_get_errstatus().ne.0) return 
  info=0
  name='psb_bjac_bld'
  call psb_erractionsave(err_act)

  ictxt=psb_cd_get_context(desc_a)
  call psb_info(ictxt, me, np)

  m = a%m
  if (m < 0) then
    info = 10
    int_err(1) = 1
    int_err(2) = m
    call psb_errpush(info,name,i_err=int_err)
    goto 9999
  endif
  trans = 'N'
  unitd = 'U'
  if (p%iprcparm(n_ovr_) < 0) then
    info = 11
    int_err(1) = 1
    int_err(2) = p%iprcparm(n_ovr_)
    call psb_errpush(info,name,i_err=int_err)
    goto 9999
  endif

  call psb_nullify_sp(blck)
  call psb_nullify_sp(atmp)

  t1= psb_wtime()

  if(debug) write(0,*)me,': calling psb_asmatbld',p%iprcparm(p_type_),p%iprcparm(n_ovr_)
  if (debug) call psb_barrier(ictxt)
  call psb_asmatbld(p%iprcparm(p_type_),p%iprcparm(n_ovr_),a,&
       & blck,desc_a,upd,p%desc_data,info,outfmt=coofmt)

  if(info/=0) then
    info=4010
    ch_err='psb_asmatbld'
    call psb_errpush(info,name,a_err=ch_err)
    goto 9999
  end if

  t2= psb_wtime()
  if (debug) write(0,*)me,': out of psb_asmatbld'
  if (debug) call psb_barrier(ictxt)


  if (p%iprcparm(iren_) > 0) then 

    !
    ! Here we allocate a full copy to hold local A and received BLK
    ! Done inside sp_renum.
    !

    call  psb_sp_renum(a,desc_a,blck,p,atmp,info)

    if(info/=0) then
      info=4010
      ch_err='psb_sp_renum'
      call psb_errpush(info,name,a_err=ch_err)
      goto 9999
    end if

    t3 = psb_wtime()
    if (debugprt) then 
      call psb_barrier(ictxt)
      open(40+me) 
      call psb_csprt(40+me,atmp,head='% Local matrix')
      close(40+me)
    endif
    if (debug) write(0,*) me,' Factoring rows ',&
         &atmp%m,a%m,blck%m,atmp%ia2(atmp%m+1)-1

    select case(p%iprcparm(f_type_))

    case(f_ilu_n_,f_ilu_e_) 

      call psb_ipcoo2csr(atmp,info)
      if (info /= 0) then
        info=4010
        call psb_errpush(info,name,a_err='psb_ipcoo2csr')
        goto 9999
      end if

      call psb_ilu_bld(atmp,p%desc_data,p,upd,info)

      if(info/=0) then
        info=4010
        call psb_errpush(info,name,a_err='psb_ilu_bld')
        goto 9999
      end if

      if (debugprt) then 

        open(80+me)

        call psb_csprt(80+me,p%av(l_pr_),head='% Local L factor')
        write(80+me,*) '% Diagonal: ',p%av(l_pr_)%m
        do i=1,p%av(l_pr_)%m
          write(80+me,*) i,i,p%d(i)
        enddo
        call psb_csprt(80+me,p%av(u_pr_),head='% Local U factor')

        close(80+me)
      endif


    case(f_slu_)

      call psb_ipcoo2csr(atmp,info)
      if (info /= 0) then
        info=4010
        call psb_errpush(info,name,a_err='psb_ipcoo2csr')
        goto 9999
      end if

      call psb_slu_bld(atmp,p%desc_data,p,info)
      if(info /= 0) then
        info=4010
        call psb_errpush(info,name,a_err='slu_bld')
        goto 9999
      end if

    case(f_umf_)

      call psb_ipcoo2csc(atmp,info)
      if (info /= 0) then
        info=4010
        call psb_errpush(info,name,a_err='psb_ipcoo2csc')
        goto 9999
      end if

      call psb_umf_bld(atmp,p%desc_data,p,info)
      if(debug) write(0,*)me,': Done umf_bld ',info
      if (info /= 0) then
        info = 4010
        call psb_errpush(info,name,a_err='umf_bld')
        goto 9999
      end if

    case(f_none_) 
      info=4010
      call psb_errpush(info,name,a_err='Inconsistent prec  f_none_')
      goto 9999

    case default
      info=4010
      call psb_errpush(info,name,a_err='Unknown f_type_')
      goto 9999
    end select



    call psb_sp_free(atmp,info) 
    if(info/=0) then
      info=4010
      call psb_errpush(info,name,a_err='psb_sp_free')
      goto 9999
    end if


  else if (p%iprcparm(iren_) == 0) then


    select case(p%iprcparm(f_type_))

    case(f_ilu_n_,f_ilu_e_) 

      call psb_ipcoo2csr(blck,info,rwshr=.true.)

      if (info==0) call psb_ilu_bld(a,desc_a,p,upd,info,blck=blck)

      if(info/=0) then
        info=4010
        call psb_errpush(info,name,a_err='psb_ilu_bld')
        goto 9999
      end if

      if (debugprt) then 

        open(80+me)

        call psb_csprt(80+me,p%av(l_pr_),head='% Local L factor')
        write(80+me,*) '% Diagonal: ',p%av(l_pr_)%m
        do i=1,p%av(l_pr_)%m
          write(80+me,*) i,i,p%d(i)
        enddo
        call psb_csprt(80+me,p%av(u_pr_),head='% Local U factor')

        close(80+me)
      endif



    case(f_slu_)

      atmp%fida='COO'
      call psb_csdp(a,atmp,info)
      if (info /= 0) then
        info=4010
        call psb_errpush(info,name,a_err='psb_csdp')
        goto 9999
      end if
      call psb_rwextd(atmp%m+blck%m,atmp,info,blck,rowscale=.true.) 
      call psb_ipcoo2csr(atmp,info)
      call psb_slu_bld(atmp,p%desc_data,p,info)
      if(info /= 0) then
        info=4010
        call psb_errpush(info,name,a_err='slu_bld')
        goto 9999
      end if

      call psb_sp_free(atmp,info) 
      if(info/=0) then
        info=4010
        call psb_errpush(info,name,a_err='psb_sp_free')
        goto 9999
      end if


    case(f_umf_)

      atmp%fida='COO'
      atmp%fida='COO'
      call psb_csdp(a,atmp,info)
      if (info /= 0) then
        info=4010
        call psb_errpush(info,name,a_err='psb_csdp')
        goto 9999
      end if
      call psb_rwextd(atmp%m+blck%m,atmp,info,blck,rowscale=.true.) 
      if (info == 0) call psb_ipcoo2csc(atmp,info)
      if (info /= 0) then
        info=4010
        call psb_errpush(info,name,a_err='psb_ipcoo2csc')
        goto 9999
      end if

      call psb_umf_bld(atmp,p%desc_data,p,info)
      if(debug) write(0,*)me,': Done umf_bld ',info
      if (info /= 0) then
        info = 4010
        call psb_errpush(info,name,a_err='umf_bld')
        goto 9999
      end if

      call psb_sp_free(atmp,info) 
      if(info/=0) then
        info=4010
        call psb_errpush(info,name,a_err='psb_sp_free')
        goto 9999
      end if


    case(f_none_) 
      info=4010
      call psb_errpush(info,name,a_err='Inconsistent prec  f_none_')
      goto 9999

    case default
      info=4010
      call psb_errpush(info,name,a_err='Unknown f_type_')
      goto 9999
    end select


  endif

  t6 = psb_wtime()

  call psb_sp_free(blck,info)
  if(info/=0) then
    info=4010
    ch_err='psb_sp_free'
    call psb_errpush(info,name,a_err=ch_err)
    goto 9999
  end if

  if (debug) write(0,*) me,'End of ilu_bld'

  call psb_erractionrestore(err_act)
  return

9999 continue
  call psb_erractionrestore(err_act)
  if (err_act.eq.psb_act_abort_) then
    call psb_error()
    return
  end if
  return


end subroutine psb_zbjac_bld

