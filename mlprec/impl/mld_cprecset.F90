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
! File: mld_cprecset.f90
!
! Subroutine: mld_cprecseti
! Version: complex
!
!  This routine sets the integer parameters defining the preconditioner. More
!  precisely, the integer parameter identified by 'what' is assigned the value
!  contained in 'val'.
!  For the multilevel preconditioners, the levels are numbered in increasing
!  order starting from the finest one, i.e. level 1 is the finest level. 
!
!  To set character and complex parameters, see mld_cprecsetc and mld_cprecsetr,
!  respectively.
!
!
! Arguments:
!    p       -  type(mld_cprec_type), input/output.
!               The preconditioner data structure.
!    what    -  integer, input.
!               The number identifying the parameter to be set.
!               A mnemonic constant has been associated to each of these
!               numbers, as reported in the MLD2P4 User's and Reference Guide.
!    val     -  integer, input.
!               The value of the parameter to be set. The list of allowed
!               values is reported in the MLD2P4 User's and Reference Guide.
!    info    -  integer, output.
!               Error code.
!    ilev    -  integer, optional, input.
!               For the multilevel preconditioner, the level at which the
!               preconditioner parameter has to be set. 
!               If nlev is not present, the parameter identified by 'what'
!               is set at all the appropriate levels.
!
!  NOTE: currently, the use of the argument ilev is not "safe" and is reserved to
!  MLD2P4 developers. Indeed, by using ilev it is possible to set different values
!  of the same parameter at different levels 1,...,nlev-1, even in cases where
!  the parameter must have the same value at all the levels but the coarsest one.
!  For this reason, the interface mld_precset to this routine has been built in
!  such a way that ilev is not visible to the user (see mld_prec_mod.f90).
!   
subroutine mld_cprecseti(p,what,val,info,ilev,ilmax,pos)

  use psb_base_mod
  use mld_c_prec_mod, mld_protect_name => mld_cprecseti
  use mld_c_jac_smoother
  use mld_c_as_smoother
  use mld_c_diag_solver
  use mld_c_ilu_solver
  use mld_c_id_solver
  use mld_c_gs_solver
#if defined(HAVE_SLU_)
  use mld_c_slu_solver
#endif
#if defined(HAVE_MUMPS_)
  use mld_c_mumps_solver
#endif

  implicit none

  ! Arguments
  class(mld_cprec_type), intent(inout)     :: p
  integer(psb_ipk_), intent(in)           :: what 
  integer(psb_ipk_), intent(in)           :: val
  integer(psb_ipk_), intent(out)          :: info
  integer(psb_ipk_), optional, intent(in) :: ilev,ilmax
  character(len=*), optional, intent(in)      :: pos

  ! Local variables
  integer(psb_ipk_)                      :: ilev_, nlev_, ilmax_, il
  character(len=*), parameter            :: name='mld_precseti'

  info = psb_success_

  if (.not.allocated(p%precv)) then 
    info = 3111
    write(psb_err_unit,*) name,&
         & ': Error: uninitialized preconditioner,',&
         &' should call MLD_PRECINIT'
    return 
  endif
  nlev_ = size(p%precv)

  if (present(ilev)) then 
    ilev_ = ilev
    if (present(ilmax)) then
      ilmax_ = ilmax
    else
      ilmax_ = ilev_
    end if
  else
    ilev_  = 1 
    ilmax_ = ilev_
  end if

  if ((ilev_<1).or.(ilev_ > nlev_)) then 
    info = -1
    write(psb_err_unit,*) name,&
         &': Error: invalid ILEV/NLEV combination',ilev_, nlev_
    return
  endif
  if ((ilmax_<1).or.(ilmax_ > nlev_)) then 
    info = -1
    write(psb_err_unit,*) name,&
         &': Error: invalid ILMAX/NLEV combination',ilmax_, nlev_
    return
  endif


  select case(what)
  case (mld_min_coarse_size_)
    p%min_coarse_size = max(val,-1)
    return
  case(mld_max_levs_)
    p%max_levs = max(val,1)
    return
  case(mld_outer_sweeps_)
    p%outer_sweeps = max(val,1)
    return
  end select

  !
  ! Set preconditioner parameters at level ilev.
  !
  if (present(ilev)) then 

      select case(what) 
      case(mld_smoother_type_,mld_sub_solve_,mld_smoother_sweeps_,&
           & mld_ml_cycle_,mld_par_aggr_alg_,mld_aggr_ord_,mld_aggr_type_,&
           & mld_aggr_prol_, mld_aggr_omega_alg_,mld_aggr_eig_,&
           & mld_sub_restr_,mld_sub_prol_, &
           & mld_sub_ovr_,mld_sub_fillin_,&
           & mld_coarse_mat_)
        do il=ilev_, ilmax_
          call p%precv(il)%set(what,val,info,pos=pos)
        end do
        
      case(mld_coarse_subsolve_)
        if (ilev_ /= nlev_) then 
          write(psb_err_unit,*) name,&
               & ': Error: Inconsistent specification of WHAT vs. ILEV'
          info = -2
          return
        end if
        call p%precv(ilev_)%set(mld_sub_solve_,val,info,pos=pos)
      case(mld_coarse_solve_)
        if (ilev_ /= nlev_) then 
          write(psb_err_unit,*) name,&
               & ': Error: Inconsistent specification of WHAT vs. ILEV'
          info = -2
          return
        end if

        if (nlev_ > 1) then 
          call p%precv(nlev_)%set(mld_coarse_solve_,val,info,pos=pos)
          select case (val) 
          case(mld_bjac_)
            call p%precv(nlev_)%set(mld_smoother_type_,val,info,pos=pos)
#if defined(HAVE_SLU_) 
            call p%precv(nlev_)%set(mld_sub_solve_,mld_slu_,info,pos=pos)
#elif defined(HAVE_MUMPS_) 
            call p%precv(nlev_)%set(mld_sub_solve_,mld_mumps_,info,pos=pos)
#else 
            call p%precv(nlev_)%set(mld_sub_solve_,mld_ilu_n_,info,pos=pos)
#endif
            call p%precv(nlev_)%set(mld_coarse_mat_,mld_distr_mat_,info,pos=pos)
          case(mld_slu_)
#if defined(HAVE_SLU_)
          call p%precv(nlev_)%set(mld_smoother_type_,mld_bjac_,info,pos=pos)
          call p%precv(nlev_)%set(mld_sub_solve_,val,info,pos=pos)
          call p%precv(nlev_)%set(mld_coarse_mat_,mld_repl_mat_,info,pos=pos)
#elif defined(HAVE_MUMPS_)
          call p%precv(nlev_)%set(mld_smoother_type_,mld_bjac_,info,pos=pos)
          call p%precv(nlev_)%set(mld_sub_solve_,mld_mumps_,info,pos=pos)
          call p%precv(nlev_)%set(mld_coarse_mat_,mld_distr_mat_,info,pos=pos)
#else 
          call p%precv(nlev_)%set(mld_smoother_type_,mld_bjac_,info,pos=pos)
          call p%precv(nlev_)%set(mld_sub_solve_,mld_ilu_n_,info,pos=pos)
          call p%precv(nlev_)%set(mld_coarse_mat_,mld_distr_mat_,info,pos=pos)
#endif
            
          case(mld_ilu_n_, mld_ilu_t_,mld_milu_n_)
            call p%precv(nlev_)%set(mld_smoother_type_,mld_bjac_,info,pos=pos)
            call p%precv(nlev_)%set(mld_sub_solve_,val,info,pos=pos)
            call p%precv(nlev_)%set(mld_coarse_mat_,mld_repl_mat_,info,pos=pos)
          case(mld_mumps_)
#if defined(HAVE_MUMPS_)          
          call p%precv(nlev_)%set(mld_smoother_type_,mld_bjac_,info,pos=pos)
          call p%precv(nlev_)%set(mld_sub_solve_,val,info,pos=pos)
          call p%precv(nlev_)%set(mld_coarse_mat_,mld_distr_mat_,info,pos=pos)
#else 
          call p%precv(nlev_)%set(mld_smoother_type_,mld_bjac_,info,pos=pos)
          call p%precv(nlev_)%set(mld_sub_solve_,mld_ilu_n_,info,pos=pos)
          call p%precv(nlev_)%set(mld_coarse_mat_,mld_distr_mat_,info,pos=pos)
#endif
       case(mld_umf_)
#if defined(HAVE_SLU_)
          call p%precv(nlev_)%set(mld_smoother_type_,mld_bjac_,info,pos=pos)
          call p%precv(nlev_)%set(mld_sub_solve_,mld_slu_,info,pos=pos)
          call p%precv(nlev_)%set(mld_coarse_mat_,mld_repl_mat_,info,pos=pos)
#elif defined(HAVE_MUMPS_)
          call p%precv(nlev_)%set(mld_smoother_type_,mld_bjac_,info,pos=pos)
          call p%precv(nlev_)%set(mld_sub_solve_,mld_mumps_,info,pos=pos)
          call p%precv(nlev_)%set(mld_coarse_mat_,mld_distr_mat_,info,pos=pos)
#else 
          call p%precv(nlev_)%set(mld_smoother_type_,mld_bjac_,info,pos=pos)
          call p%precv(nlev_)%set(mld_sub_solve_,mld_ilu_n_,info,pos=pos)
          call p%precv(nlev_)%set(mld_coarse_mat_,mld_distr_mat_,info,pos=pos)
#endif
          
        case(mld_sludist_)
#if defined(HAVE_SLU_)
          call p%precv(nlev_)%set(mld_smoother_type_,mld_bjac_,info,pos=pos)
          call p%precv(nlev_)%set(mld_sub_solve_,mld_slu_,info,pos=pos)
          call p%precv(nlev_)%set(mld_coarse_mat_,mld_repl_mat_,info,pos=pos)
#elif defined(HAVE_MUMPS_)
          call p%precv(nlev_)%set(mld_smoother_type_,mld_bjac_,info,pos=pos)
          call p%precv(nlev_)%set(mld_sub_solve_,mld_mumps_,info,pos=pos)
          call p%precv(nlev_)%set(mld_coarse_mat_,mld_distr_mat_,info,pos=pos)
#else 
          call p%precv(nlev_)%set(mld_smoother_type_,mld_bjac_,info,pos=pos)
          call p%precv(nlev_)%set(mld_sub_solve_,mld_ilu_n_,info,pos=pos)
          call p%precv(nlev_)%set(mld_coarse_mat_,mld_distr_mat_,info,pos=pos)
#endif
          case(mld_jac_)
            call p%precv(nlev_)%set(mld_smoother_type_,mld_bjac_,info,pos=pos)
            call p%precv(nlev_)%set(mld_sub_solve_,mld_diag_scale_,info,pos=pos)
            call p%precv(nlev_)%set(mld_coarse_mat_,mld_distr_mat_,info,pos=pos)
          end select

        endif
      case(mld_coarse_sweeps_)
        if (ilev_ /= nlev_) then 
          write(psb_err_unit,*) name,&
               & ': Error: Inconsistent specification of WHAT vs. ILEV'
          info = -2
          return
        end if
        call p%precv(nlev_)%set(mld_smoother_sweeps_,val,info,pos=pos)

      case(mld_coarse_fillin_)
        if (ilev_ /= nlev_) then 
          write(psb_err_unit,*) name,&
               & ': Error: Inconsistent specification of WHAT vs. ILEV'
          info = -2
          return
        end if
        call p%precv(nlev_)%set(mld_sub_fillin_,val,info,pos=pos)
      case default
        do il=ilev_, ilmax_
          call p%precv(il)%set(what,val,info,pos=pos)
        end do
      end select

  else if (.not.present(ilev)) then 
    !
    ! ilev not specified: set preconditioner parameters at all the appropriate
    ! levels
    !
    select case(what) 
    case(mld_sub_solve_,mld_sub_restr_,mld_sub_prol_,&
         & mld_sub_ovr_,mld_sub_fillin_,&
         & mld_smoother_sweeps_,mld_smoother_type_)
      do ilev_=1,max(1,nlev_-1)
        call p%precv(ilev_)%set(what,val,info,pos=pos)
        if (info /= 0) return 
      end do

    case(mld_ml_cycle_,mld_par_aggr_alg_,mld_aggr_ord_,mld_aggr_type_,mld_aggr_prol_,&
         & mld_aggr_eig_,mld_aggr_filter_)
      do ilev_=1,nlev_
        call p%precv(ilev_)%set(what,val,info,pos=pos)
      end do

    case(mld_coarse_mat_)
      if (nlev_ > 1) then 
        call p%precv(nlev_)%set(mld_coarse_mat_,val,info,pos=pos)
      end if

    case(mld_coarse_solve_)
      if (nlev_ > 1) then 
        call p%precv(nlev_)%set('COARSE_SOLVE',val,info,pos=pos)
        select case (val) 
        case(mld_bjac_)
          call p%precv(nlev_)%set(mld_smoother_type_,mld_bjac_,info,pos=pos)
#if defined(HAVE_SLU_)
          call p%precv(nlev_)%set(mld_sub_solve_,mld_slu_,info,pos=pos)
#elif defined(HAVE_MUMPS_)
          call p%precv(nlev_)%set(mld_sub_solve_,mld_mumps_,info,pos=pos)
#else
          call p%precv(nlev_)%set(mld_sub_solve_,mld_ilu_n_,info,pos=pos)
#endif
          call p%precv(nlev_)%set(mld_coarse_mat_,mld_distr_mat_,info)
        case(mld_slu_)
#if defined(HAVE_SLU_)
          call p%precv(nlev_)%set(mld_smoother_type_,mld_bjac_,info,pos=pos)
          call p%precv(nlev_)%set(mld_sub_solve_,val,info,pos=pos)
          call p%precv(nlev_)%set(mld_coarse_mat_,mld_repl_mat_,info,pos=pos)
#elif defined(HAVE_MUMPS_)
          call p%precv(nlev_)%set(mld_smoother_type_,mld_bjac_,info,pos=pos)
          call p%precv(nlev_)%set(mld_sub_solve_,mld_mumps_,info,pos=pos)
          call p%precv(nlev_)%set(mld_coarse_mat_,mld_distr_mat_,info,pos=pos)
#else 
          call p%precv(nlev_)%set(mld_smoother_type_,mld_bjac_,info,pos=pos)
          call p%precv(nlev_)%set(mld_sub_solve_,mld_ilu_n_,info,pos=pos)
          call p%precv(nlev_)%set(mld_coarse_mat_,mld_distr_mat_,info,pos=pos)
#endif
        case(mld_ilu_n_, mld_ilu_t_,mld_milu_n_)
          call p%precv(nlev_)%set(mld_smoother_type_,mld_bjac_,info,pos=pos)
          call p%precv(nlev_)%set(mld_sub_solve_,val,info,pos=pos)
          call p%precv(nlev_)%set(mld_coarse_mat_,mld_repl_mat_,info,pos=pos)
        case(mld_mumps_)
#if defined(HAVE_MUMPS_)          
          call p%precv(nlev_)%set(mld_smoother_type_,mld_bjac_,info,pos=pos)
          call p%precv(nlev_)%set(mld_sub_solve_,val,info,pos=pos)
          call p%precv(nlev_)%set(mld_coarse_mat_,mld_distr_mat_,info,pos=pos)
#else 
          call p%precv(nlev_)%set(mld_smoother_type_,mld_bjac_,info,pos=pos)
          call p%precv(nlev_)%set(mld_sub_solve_,mld_ilu_n_,info,pos=pos)
          call p%precv(nlev_)%set(mld_coarse_mat_,mld_distr_mat_,info,pos=pos)
#endif
       case(mld_umf_)
#if defined(HAVE_SLU_)
          call p%precv(nlev_)%set(mld_smoother_type_,mld_bjac_,info,pos=pos)
          call p%precv(nlev_)%set(mld_sub_solve_,mld_slu_,info,pos=pos)
          call p%precv(nlev_)%set(mld_coarse_mat_,mld_repl_mat_,info,pos=pos)
#elif defined(HAVE_MUMPS_)
          call p%precv(nlev_)%set(mld_smoother_type_,mld_bjac_,info,pos=pos)
          call p%precv(nlev_)%set(mld_sub_solve_,mld_mumps_,info,pos=pos)
          call p%precv(nlev_)%set(mld_coarse_mat_,mld_distr_mat_,info,pos=pos)
#else 
          call p%precv(nlev_)%set(mld_smoother_type_,mld_bjac_,info,pos=pos)
          call p%precv(nlev_)%set(mld_sub_solve_,mld_ilu_n_,info,pos=pos)
          call p%precv(nlev_)%set(mld_coarse_mat_,mld_distr_mat_,info,pos=pos)
#endif
          
        case(mld_sludist_)
#if defined(HAVE_SLU_)
          call p%precv(nlev_)%set(mld_smoother_type_,mld_bjac_,info,pos=pos)
          call p%precv(nlev_)%set(mld_sub_solve_,mld_slu_,info,pos=pos)
          call p%precv(nlev_)%set(mld_coarse_mat_,mld_repl_mat_,info,pos=pos)
#elif defined(HAVE_MUMPS_)
          call p%precv(nlev_)%set(mld_smoother_type_,mld_bjac_,info,pos=pos)
          call p%precv(nlev_)%set(mld_sub_solve_,mld_mumps_,info,pos=pos)
          call p%precv(nlev_)%set(mld_coarse_mat_,mld_distr_mat_,info,pos=pos)
#else 
          call p%precv(nlev_)%set(mld_smoother_type_,mld_bjac_,info,pos=pos)
          call p%precv(nlev_)%set(mld_sub_solve_,mld_ilu_n_,info,pos=pos)
          call p%precv(nlev_)%set(mld_coarse_mat_,mld_distr_mat_,info,pos=pos)
#endif
        case(mld_jac_)
          call p%precv(nlev_)%set(mld_smoother_type_,mld_bjac_,info,pos=pos)
          call p%precv(nlev_)%set(mld_sub_solve_,mld_diag_scale_,info,pos=pos)
          call p%precv(nlev_)%set(mld_coarse_mat_,mld_distr_mat_,info,pos=pos)
        end select
      endif

    case(mld_coarse_subsolve_)
      if (nlev_ > 1) then 
        call p%precv(nlev_)%set(mld_sub_solve_,val,info,pos=pos)
      endif

    case(mld_coarse_sweeps_)

      if (nlev_ > 1) then
        call p%precv(nlev_)%set(mld_smoother_sweeps_,val,info,pos=pos)
      end if

    case(mld_coarse_fillin_)
      if (nlev_ > 1) then 
        call p%precv(nlev_)%set(mld_sub_fillin_,val,info,pos=pos)
      end if
    case default
      do ilev_=1,nlev_
        call p%precv(ilev_)%set(what,val,info,pos=pos)
      end do
    end select

  endif

end subroutine mld_cprecseti

subroutine mld_cprecsetsm(p,val,info,ilev,ilmax,pos)

  use psb_base_mod
  use mld_c_prec_mod, mld_protect_name => mld_cprecsetsm

  implicit none

  ! Arguments
  class(mld_cprec_type), intent(inout)         :: p
  class(mld_c_base_smoother_type), intent(in) :: val
  integer(psb_ipk_), intent(out)              :: info
  integer(psb_ipk_), optional, intent(in)     :: ilev,ilmax
  character(len=*), optional, intent(in)      :: pos

  ! Local variables
  integer(psb_ipk_)                      :: ilev_, nlev_, ilmin_, ilmax_
  character(len=*), parameter            :: name='mld_precsetsm'

  info = psb_success_

  if (.not.allocated(p%precv)) then 
    info = 3111
    write(psb_err_unit,*) name,&
         & ': Error: uninitialized preconditioner,',&
         &' should call MLD_PRECINIT'
    return 
  endif
  nlev_ = size(p%precv)

  if (present(ilev)) then 
    ilev_ = ilev
    ilmin_ = ilev
    if (present(ilmax)) then
      ilmax_ = ilmax
    else
      ilmax_ = ilev_
    end if
  else
    ilev_ = 1 
    ilmin_ = 1
    ilmax_ = nlev_
  end if

  if ((ilev_<1).or.(ilev_ > nlev_)) then 
    info = -1
    write(psb_err_unit,*) name,&
         & ': Error: invalid ILEV/NLEV combination',ilev_, nlev_
    return
  endif
  if ((ilmax_<1).or.(ilmax_ > nlev_)) then 
    info = -1
    write(psb_err_unit,*) name,&
         &': Error: invalid ILMAX/NLEV combination',ilmax_, nlev_
    return
  endif  

  do ilev_ = ilmin_, ilmax_ 
    call p%precv(ilev_)%set(val,info,pos=pos)
    if (info /= 0) return 
  end do

end subroutine mld_cprecsetsm

subroutine mld_cprecsetsv(p,val,info,ilev,ilmax,pos)

  use psb_base_mod
  use mld_c_prec_mod, mld_protect_name => mld_cprecsetsv

  implicit none

  ! Arguments
  class(mld_cprec_type), intent(inout)       :: p
  class(mld_c_base_solver_type), intent(in) :: val
  integer(psb_ipk_), intent(out)            :: info
  integer(psb_ipk_), optional, intent(in)   :: ilev,ilmax
  character(len=*), optional, intent(in)      :: pos

  ! Local variables
  integer(psb_ipk_)                       :: ilev_, nlev_, ilmin_, ilmax_
  character(len=*), parameter            :: name='mld_precsetsv'

  info = psb_success_

  if (.not.allocated(p%precv)) then 
    info = 3111
    write(psb_err_unit,*) name,&
         & ': Error: uninitialized preconditioner,',&
         &' should call MLD_PRECINIT'
    return 
  endif
  nlev_ = size(p%precv)

  if (present(ilev)) then 
    ilev_ = ilev
    ilmin_ = ilev
    if (present(ilmax)) then
      ilmax_ = ilmax
    else
      ilmax_ = ilev_
    end if
  else
    ilev_ = 1 
    ilmin_ = 1
    ilmax_ = nlev_
  end if

  if ((ilev_<1).or.(ilev_ > nlev_)) then 
    info = -1
    write(psb_err_unit,*) name,&
         & ': Error: invalid ILEV/NLEV combination',ilev_, nlev_
    return
  endif
  if ((ilmax_<1).or.(ilmax_ > nlev_)) then 
    info = -1
    write(psb_err_unit,*) name,&
         &': Error: invalid ILMAX/NLEV combination',ilmax_, nlev_
    return
  endif  

  do ilev_ = ilmin_, ilmax_ 
    call p%precv(ilev_)%set(val,info,pos=pos)
    if (info /= 0) return 
  end do

end subroutine mld_cprecsetsv

!
! Subroutine: mld_cprecsetc
! Version: complex
!
!  This routine sets the character parameters defining the preconditioner. More
!  precisely, the character parameter identified by 'what' is assigned the value
!  contained in 'val'.
!  For the multilevel preconditioners, the levels are numbered in increasing
!  order starting from the finest one, i.e. level 1 is the finest level. 
!
!  To set integer and complex parameters, see mld_cprecseti and mld_cprecsetr,
!  respectively.
!
!
! Arguments:
!    p       -  type(mld_cprec_type), input/output.
!               The preconditioner data structure.
!    what    -  integer, input.
!               The number identifying the parameter to be set.
!               A mnemonic constant has been associated to each of these
!               numbers, as reported in the MLD2P4 User's and Reference Guide.
!    string  -  character(len=*), input.
!               The value of the parameter to be set. The list of allowed
!               values is reported in the MLD2P4 User's and Reference Guide.
!    info    -  integer, output.
!               Error code.
!    ilev    -  integer, optional, input.
!               For the multilevel preconditioner, the level at which the
!               preconditioner parameter has to be set. 
!               If nlev is not present, the parameter identified by 'what'
!               is set at all the appropriate levels.
!
!  NOTE: currently, the use of the argument ilev is not "safe" and is reserved to
!  MLD2P4 developers. Indeed, by using ilev it is possible to set different values
!  of the same parameter at different levels 1,...,nlev-1, even in cases where
!  the parameter must have the same value at all the levels but the coarsest one.
!  For this reason, the interface mld_precset to this routine has been built in
!  such a way that ilev is not visible to the user (see mld_prec_mod.f90).
!   
subroutine mld_cprecsetc(p,what,string,info,ilev,ilmax,pos)

  use psb_base_mod
  use mld_c_prec_mod, mld_protect_name => mld_cprecsetc

  implicit none

  ! Arguments
  class(mld_cprec_type), intent(inout)     :: p
  integer(psb_ipk_), intent(in)           :: what 
  character(len=*), intent(in)            :: string
  integer(psb_ipk_), intent(out)          :: info
  integer(psb_ipk_), optional, intent(in) :: ilev,ilmax
  character(len=*), optional, intent(in)      :: pos

  ! Local variables
  integer(psb_ipk_)                      :: ilev_, nlev_,val,ilmax_, il
  character(len=*), parameter            :: name='mld_precsetc'

  info = psb_success_

  if (.not.allocated(p%precv)) then 
    info = 3111
    return 
  endif
  nlev_ = size(p%precv)

  if (present(ilev)) then 
    ilev_ = ilev
  else
    ilev_ = 1 
  end if

  if ((ilev_<1).or.(ilev_ > nlev_)) then 
    write(psb_err_unit,*) name,&
         & ': Error: invalid ILEV/NLEV combination',ilev_, nlev_
    info = -1
    return
  endif

  val =  mld_stringval(string)
  if (val >=0) then
    call p%set(what,val,info,ilev=ilev,ilmax=ilmax,pos=pos)
  else
    nlev_ = size(p%precv)
    
    if (present(ilev)) then 
      ilev_ = ilev
      if (present(ilmax)) then
        ilmax_ = ilmax
      else
        ilmax_ = ilev_
      end if
    else
      ilev_  = 1 
      ilmax_ = ilev_
    end if
    if ((ilev_<1).or.(ilev_ > nlev_)) then 
      info = -1
      write(psb_err_unit,*) name,&
           &': Error: invalid ILEV/NLEV combination',ilev_, nlev_
      return
    endif
    if ((ilmax_<1).or.(ilmax_ > nlev_)) then 
      info = -1
      write(psb_err_unit,*) name,&
           &': Error: invalid ILMAX/NLEV combination',ilmax_, nlev_
      return
    endif
    do il=ilev_, ilmax_
      call p%precv(il)%set(what,string,info,pos=pos)
    end do
  end if


end subroutine mld_cprecsetc


!
! Subroutine: mld_cprecsetr
! Version: complex
!
!  This routine sets the complex parameters defining the preconditioner. More
!  precisely, the complex parameter identified by 'what' is assigned the value
!  contained in 'val'.
!  For the multilevel preconditioners, the levels are numbered in increasing
!  order starting from the finest one, i.e. level 1 is the finest level. 
!
!  To set integer and character parameters, see mld_cprecseti and mld_cprecsetc,
!  respectively.
!
! Arguments:
!    p       -  type(mld_cprec_type), input/output.
!               The preconditioner data structure.
!    what    -  integer, input.
!               The number identifying the parameter to be set.
!               A mnemonic constant has been associated to each of these
!               numbers, as reported in the MLD2P4 User's and Reference Guide.
!    val     -  real(psb_spk_), input.
!               The value of the parameter to be set. The list of allowed
!               values is reported in the MLD2P4 User's and Reference Guide.
!    info    -  integer, output.
!               Error code.
!    ilev    -  integer, optional, input.
!               For the multilevel preconditioner, the level at which the
!               preconditioner parameter has to be set. 
!               If nlev is not present, the parameter identified by 'what'
!               is set at all the appropriate levels.
!
!  NOTE: currently, the use of the argument ilev is not "safe" and is reserved to
!  MLD2P4 developers. Indeed, by using ilev it is possible to set different values
!  of the same parameter at different levels 1,...,nlev-1, even in cases where
!  the parameter must have the same value at all the levels but the coarsest one.
!  For this reason, the interface mld_precset to this routine has been built in
!  such a way that ilev is not visible to the user (see mld_prec_mod.f90).
!   
subroutine mld_cprecsetr(p,what,val,info,ilev,ilmax,pos)

  use psb_base_mod
  use mld_c_prec_mod, mld_protect_name => mld_cprecsetr

  implicit none

  ! Arguments
  class(mld_cprec_type), intent(inout)     :: p
  integer(psb_ipk_), intent(in)           :: what 
  real(psb_spk_), intent(in)              :: val
  integer(psb_ipk_), intent(out)          :: info
  integer(psb_ipk_), optional, intent(in) :: ilev,ilmax
  character(len=*), optional, intent(in)  :: pos

! Local variables
  integer(psb_ipk_)                      :: ilev_,nlev_, ilmax_, il
  real(psb_spk_)                         :: thr 
  character(len=*), parameter            :: name='mld_precsetr'

  info = psb_success_

  select case(what)
  case (mld_min_cr_ratio_)
    p%min_cr_ratio = max(sone,val)
    return
  end select
  
  if (.not.allocated(p%precv)) then 
    write(psb_err_unit,*) name,&
         &': Error: uninitialized preconditioner,',&
         &' should call MLD_PRECINIT' 
    info = 3111
    return 
  endif
  nlev_ = size(p%precv)
  if (present(ilev)) then 
    ilev_ = ilev
    if (present(ilmax)) then
      ilmax_ = ilmax
    else
      ilmax_ = ilev_
    end if
  else
    ilev_  = 1 
    ilmax_ = ilev_
  end if
  if ((ilev_<1).or.(ilev_ > nlev_)) then 
    info = -1
    write(psb_err_unit,*) name,&
         &': Error: invalid ILEV/NLEV combination',ilev_, nlev_
    return
  endif
  if ((ilmax_<1).or.(ilmax_ > nlev_)) then 
    info = -1
    write(psb_err_unit,*) name,&
         &': Error: invalid ILMAX/NLEV combination',ilmax_, nlev_
    return
  endif

  !
  ! Set preconditioner parameters at level ilev.
  !
  if (present(ilev)) then 

    do il=ilev_, ilmax_
      call p%precv(il)%set(what,val,info,pos=pos)
    end do

  else if (.not.present(ilev)) then 
      !
      ! ilev not specified: set preconditioner parameters at all the appropriate levels
      !

      select case(what) 
      case(mld_coarse_iluthrs_)
        ilev_=nlev_
        call p%precv(ilev_)%set(mld_sub_iluthrs_,val,info,pos=pos)

      case default

        do il=1,nlev_
          call p%precv(il)%set(what,val,info,pos=pos)
        end do
      end select

  endif

end subroutine mld_cprecsetr




