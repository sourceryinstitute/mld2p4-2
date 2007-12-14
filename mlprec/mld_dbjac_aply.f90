!!$
!!$ 
!!$                                MLD2P4
!!$  MultiLevel Domain Decomposition Parallel Preconditioners Package
!!$             based on PSBLAS (Parallel Sparse BLAS v.2.0)
!!$  
!!$  (C) Copyright 2007  Alfredo Buttari      University of Rome Tor Vergata
!!$                      Pasqua D'Ambra       ICAR-CNR, Naples
!!$                      Daniela di Serafino  Second University of Naples
!!$                      Salvatore Filippone  University of Rome Tor Vergata       
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
! File mld_dbjac_aply.f90.
!
! Subroutine: mld_dbjac_aply.
! Version: real. 
!
!  This routine computes
!
!                       Y = beta*Y + alpha*op(K^(-1))*X,
!
!  where
!  - K is a suitable matrix, as specified below,
!  - op(K^(-1)) is K^(-1) or its transpose, according to the value of trans,
!  - X and Y are vectors,
!  - alpha and beta are scalars.
!
!  Depending on K, alpha, beta (and on the communication descriptor desc_data
!  - see the arguments below), the above computation may correspond to one of
!  the following tasks:
!
!  1. Application of a block-Jacobi preconditioner associated to a matrix A
!     distributed among the processes. Here K is the preconditioner, op(K^(-1))
!     = K^(-1), alpha = 1 and beta = 0.
!
!  2. Application of block-Jacobi sweeps to compute an approximate solution of
!     a linear system
!                                    A*Y = X,
!
!     distributed among the processes (note that a single block-Jacobi sweep,
!     with null starting guess, corresponds to the application of a block-Jacobi
!     preconditioner). Here K^(-1) denotes the iteration matrix of the
!     block-Jacobi solver, op(K^(-1)) = K^(-1), alpha = 1 and beta = 0.
!
!  3. Solution, through      the LU factorization, of a linear system
!
!                                    A*Y = X,
!
!     distributed among the processes. Here K = L*U = A, op(K^(-1)) = K^(-1),
!     alpha = 1 and beta = 0.
!
!  4. (Approximate) solution, through the LU or incomplete LU factorization, of
!     a linear system
!                                    A*Y = X,
!
!        replicated on the processes. Here K = L*U = A or K = L*U ~ A,      op(K^(-1)) =
!     K^(-1), alpha = 1 and beta = 0.
!
!  The block-Jacobi preconditioner or solver and the L and U factors of the LU
!  or ILU factorizations have been built by the routine mld_dbjac_bld and stored
!  into the 'base preconditioner' data structure prec. See mld_dbjac_bld for more
!  details.
!
!  This routine is used by mld_dbaseprec_aply, to apply a 'base' block-Jacobi or
!  Additive Schwarz (AS) preconditioner at any level of a multilevel preconditioner,
!  or a block-Jacobi or LU or ILU solver at the coarsest level of a multilevel
!  preconditioner. 
!
!  Inside mld_dbaseprec_aply, tasks 1, 3 and 4 may be selected if
!  prec%iprcparm(smooth_sweeps_) = 1, while task 2 if prec%iprcparm(smooth_sweeps_)
!   > 1. Furthermore, tasks 1, 2 and 3 may be performed if the matrix A is
!  distributed among the processes (prec%iprcparm(mld_coarse_mat_) = mld_distr_mat_),
!  while task 4 may be performed if A is replicated on the processes
!  (prec%iprcparm(mld_coarse_mat_) = mld_repl_mat_). Note that the matrix A is
!  distributed among the processes at each level of the multilevel preconditioner,
!  except the coarsest one, where it may be either distributed or replicated on
!  the processes. Furthermore, the tasks 2, 3 and 4 are performed only at the
!  coarsest level. Note also that this routine manages implicitly the fact that
!  the matrix is distributed or replicated, i.e. it does not make any explicit
!  reference to the value of prec%iprcparm(mld_coarse_mat_).
!
!
! Arguments:
!
!   alpha      -  real(kind(0.d0)), input.
!                 The scalar alpha.
!   prec       -  type(<mld_dbaseprec_type>), input.
!                 The 'base preconditioner' data structure containing the local 
!                 part of the preconditioner or solver.
!   x          -  real(kind(0.d0)), dimension(:), input/output.
!                 The local part of the vector X.
!   beta       -  real(kind(0.d0)), input.
!                 The scalar beta.
!   y          -  real(kind(0.d0)), dimension(:), input/output.
!                 The local part of the vector Y.
!   desc_data  -  type(<psb_desc_type>), input.
!                 The communication descriptor associated to the matrix to be
!                 preconditioned or 'inverted'.
!   trans      -  character(len=1), input.
!                 If trans='N','n' then op(K^(-1)) = K^(-1);
!                 if trans='T','t' then op(K^(-1)) = K^(-T) (transpose of K^(-1)).
!                 If prec%iprcparm(smooth_sweeps_) > 1, the value of trans provided
!                 in input is ignored.
!   work       -  real(kind(0.d0)), dimension (:), target.
!                 Workspace. Its size must be at least 4*psb_cd_get_local_cols(desc_data).
!   info       -  integer, output.
!                 Error code.
!  
subroutine mld_dbjac_aply(alpha,prec,x,beta,y,desc_data,trans,work,info)

  use psb_base_mod
  use mld_prec_mod, mld_protect_name => mld_dbjac_aply

  implicit none 

  ! Arguments
  type(psb_desc_type), intent(in)      :: desc_data
  type(mld_dbaseprc_type), intent(in)  :: prec
  real(kind(0.d0)),intent(in)          :: x(:)
  real(kind(0.d0)),intent(inout)       :: y(:)
  real(kind(0.d0)),intent(in)          :: alpha,beta
  character(len=1)                     :: trans
  real(kind(0.d0)),target              :: work(:)
  integer, intent(out)                 :: info

  ! Local variables
  integer :: n_row,n_col
  real(kind(1.d0)), pointer :: ww(:), aux(:), tx(:),ty(:)
  integer :: ictxt,np,me,i, err_act, int_err(5)
  logical,parameter   :: debug=.false., debugprt=.false.
  character(len=20)   :: name

  interface 
    subroutine mld_dumf_solve(flag,m,x,b,n,ptr,info)
      integer, intent(in)  :: flag,m,n,ptr
      integer, intent(out) :: info
      real(kind(1.d0)), intent(in)    :: b(*)
      real(kind(1.d0)), intent(inout) :: x(*)
    end subroutine mld_dumf_solve
  end interface
  
  name='mld_dbjac_aply'
  info = 0
  call psb_erractionsave(err_act)

  ictxt=psb_cd_get_context(desc_data)
  call psb_info(ictxt, me, np)

  select case(toupper(trans))
  case('N')
  case('T','C')
  case default
    call psb_errpush(40,name)
    goto 9999
  end select


  n_row = psb_cd_get_local_rows(desc_data)
  n_col = psb_cd_get_local_cols(desc_data)

  if (n_col <= size(work)) then 
    ww => work(1:n_col)
    if ((4*n_col+n_col) <= size(work)) then 
      aux => work(n_col+1:)
    else
      allocate(aux(4*n_col),stat=info)
      if (info /= 0) then 
        info=4025
        call psb_errpush(info,name,i_err=(/4*n_col,0,0,0,0/),&
             & a_err='real(kind(1.d0))')
        goto 9999      
      end if

    endif
  else
    allocate(ww(n_col),aux(4*n_col),stat=info)
    if (info /= 0) then 
      info=4025
      call psb_errpush(info,name,i_err=(/5*n_col,0,0,0,0/),&
           & a_err='real(kind(1.d0))')
      goto 9999      
    end if
  endif

  if (debug) then 
    write(0,*) me,' mld_bjac_APLY: ',prec%iprcparm(mld_sub_solve_),prec%iprcparm(mld_smooth_sweeps_)
  end if
  
  if (prec%iprcparm(mld_smooth_sweeps_) == 1) then 
    !
    ! TASKS 1, 3 and 4
    !

    select case(prec%iprcparm(mld_sub_solve_))
    case(mld_ilu_n_,mld_milu_n_,mld_ilu_t_) 
      !
      ! Apply a block-Jacobi preconditioner with ILU(k)/MILU(k)/ILU(k,t)
      ! factorization of the blocks (distributed matrix) or approximately
      ! solve a system through ILU(k)/MILU(k)/ILU(k,t) (replicated matrix).
      ! 

      select case(toupper(trans))
      case('N')

        call psb_spsm(done,prec%av(mld_l_pr_),x,dzero,ww,desc_data,info,&
             & trans='N',unit='L',diag=prec%d,choice=psb_none_,work=aux)
        if(info /=0) goto 9999
        call psb_spsm(alpha,prec%av(mld_u_pr_),ww,beta,y,desc_data,info,&
             & trans='N',unit='U',choice=psb_none_, work=aux)
        if(info /=0) goto 9999

      case('T','C')
        call psb_spsm(done,prec%av(mld_u_pr_),x,dzero,ww,desc_data,info,&
             & trans=trans,unit='L',diag=prec%d,choice=psb_none_,work=aux)
        if(info /=0) goto 9999
        call psb_spsm(alpha,prec%av(mld_l_pr_),ww,beta,y,desc_data,info,&
             & trans=trans,unit='U',choice=psb_none_,work=aux)
        if(info /=0) goto 9999

      end select

    case(mld_slu_)
      !
      ! Apply a block-Jacobi preconditioner with LU factorization of the
      ! blocks (distributed matrix) or approximately solve a local linear
      ! system through LU (replicated matrix). The SuperLU package is used 
      ! to apply the LU factorization in both cases.
      !

      ww(1:n_row) = x(1:n_row)

      select case(toupper(trans))
      case('N')
        call mld_dslu_solve(0,n_row,1,ww,n_row,prec%iprcparm(mld_slu_ptr_),info)
      case('T','C')
        call mld_dslu_solve(1,n_row,1,ww,n_row,prec%iprcparm(mld_slu_ptr_),info)
      end select

      if(info /=0) goto 9999
      call psb_geaxpby(alpha,ww,beta,y,desc_data,info)

    case(mld_sludist_)
      !
      ! Solve a distributed linear system with the LU factorization.
      ! The SuperLU_DIST package is used.
      !

      ww(1:n_row) = x(1:n_row)

      select case(toupper(trans))
      case('N')
        call mld_dsludist_solve(0,n_row,1,ww,n_row,prec%iprcparm(mld_slud_ptr_),info)
      case('T','C')
        call mld_dsludist_solve(1,n_row,1,ww,n_row,prec%iprcparm(mld_slud_ptr_),info)
      end select

      if(info /=0) goto 9999
      call psb_geaxpby(alpha,ww,beta,y,desc_data,info)

    case (mld_umf_) 
      !
      ! Apply a block-Jacobi preconditioner with LU factorization of the
      ! blocks (distributed matrix) or approximately solve a local linear
      ! system through LU (replicated matrix). The UMFPACK package is used 
      ! to apply the LU factorization in both cases.
      !


      select case(toupper(trans))
      case('N')
        call mld_dumf_solve(0,n_row,ww,x,n_row,prec%iprcparm(mld_umf_numptr_),info)
      case('T','C')
        call mld_dumf_solve(1,n_row,ww,x,n_row,prec%iprcparm(mld_umf_numptr_),info)
      end select

      if(info /=0) goto 9999

      call psb_geaxpby(alpha,ww,beta,y,desc_data,info)

    case default
      write(0,*) 'Unknown factorization type in mld_bjac_aply',prec%iprcparm(mld_sub_solve_)
    end select
    if (debugprt) write(0,*)' Y: ',y(:)

  else if (prec%iprcparm(mld_smooth_sweeps_) > 1) then 

    !
    ! TASK 2
    !
    ! Apply prec%iprcparm(smooth_sweeps_) sweeps of a block-Jacobi solver
    ! to compute an approximate solution of a linear system.
    !
    ! Note: trans is always 'N' here.
    !

    if (size(prec%av) < mld_ap_nd_) then 
      info = 4011
      goto 9999
    endif

    allocate(tx(n_col),ty(n_col),stat=info)
    if (info /= 0) then 
      info=4025
      call psb_errpush(info,name,i_err=(/2*n_col,0,0,0,0/),&
           & a_err='real(kind(1.d0))')
      goto 9999      
    end if

    tx = dzero
    ty = dzero
    select case(prec%iprcparm(mld_sub_solve_)) 
    case(mld_ilu_n_,mld_milu_n_,mld_ilu_t_) 
      !
      ! Use ILU(k)/MILU(k)/ILU(k,t) on the blocks.
      !
      do i=1, prec%iprcparm(mld_smooth_sweeps_) 
        !
        ! Compute Y(j+1) = D^(-1)*(X-ND*Y(j)), where D and ND are the
        ! block diagonal part and the remaining part of the local matrix
        ! and Y(j) is the approximate solution at sweep j.
        !
        ty(1:n_row) = x(1:n_row)
        call psb_spmm(-done,prec%av(mld_ap_nd_),tx,done,ty,&
             &   prec%desc_data,info,work=aux)
        if(info /=0) goto 9999
        call psb_spsm(done,prec%av(mld_l_pr_),ty,dzero,ww,&
             & prec%desc_data,info,&
             & trans='N',unit='L',diag=prec%d,choice=psb_none_,work=aux)
        if(info /=0) goto 9999
        call psb_spsm(done,prec%av(mld_u_pr_),ww,dzero,tx,&
             & prec%desc_data,info,&
             & trans='N',unit='U',choice=psb_none_,work=aux)
        if(info /=0) goto 9999
      end do

    case(mld_sludist_) 
      !
      ! Wrong choice: SuperLU_DIST
      !
      write(0,*) 'No sense in having SuperLU_DIST with multiple Jacobi sweeps'
      info=4010
      goto 9999

    case(mld_slu_)
      !
      ! Use the LU factorization from SuperLU.
      !

      do i=1, prec%iprcparm(mld_smooth_sweeps_)
        ! 
        ! Compute Y(k+1) = D^(-1)*(X-ND*Y(k)), where D and ND are the
        ! block diagonal part and the remaining part of the local matrix
        ! and Y(j) is the approximate solution at sweep j.
        !
        ty(1:n_row) = x(1:n_row)
        call psb_spmm(-done,prec%av(mld_ap_nd_),tx,done,ty,&
             &   prec%desc_data,info,work=aux)
        if(info /=0) goto 9999

        call mld_dslu_solve(0,n_row,1,ty,n_row,prec%iprcparm(mld_slu_ptr_),info)
        if(info /=0) goto 9999
        tx(1:n_row) = ty(1:n_row)        
      end do

    case(mld_umf_)
      !
      ! Use the LU factorization from UMFPACK.
      !

      do i=1, prec%iprcparm(mld_smooth_sweeps_) 
        ! 
        ! Compute Y(k+1) = D^(-1)*(X-ND*Y(k)), where D and ND are the
        ! block diagonal part and the remaining part of the local matrix
        ! and Y(j) is the approximate solution at sweep j.
        !
        ty(1:n_row) = x(1:n_row)
        call psb_spmm(-done,prec%av(mld_ap_nd_),tx,done,ty,&
             &   prec%desc_data,info,work=aux)
        if(info /=0) goto 9999

        call mld_dumf_solve(0,n_row,ww,ty,n_row,&
             & prec%iprcparm(mld_umf_numptr_),info)
        if(info /=0) goto 9999
        tx(1:n_row) = ww(1:n_row)        
      end do

    end select

    !
    ! Put the result into the output vector Y.
    !
    call psb_geaxpby(alpha,tx,beta,y,desc_data,info)
    

    deallocate(tx,ty)

  else

    info = 10
    call psb_errpush(info,name,&
         & i_err=(/2,prec%iprcparm(mld_smooth_sweeps_),0,0,0/))
    goto 9999

  endif

  if (n_col <= size(work)) then 
    if ((4*n_col+n_col) <= size(work)) then 
    else
      deallocate(aux)
    endif
  else
    deallocate(ww,aux)
  endif

  call psb_erractionrestore(err_act)
  return

9999 continue
  call psb_errpush(info,name,i_err=int_err)
  call psb_erractionrestore(err_act)
  if (err_act.eq.psb_act_abort_) then
    call psb_error()
    return
  end if
  return

end subroutine mld_dbjac_aply

