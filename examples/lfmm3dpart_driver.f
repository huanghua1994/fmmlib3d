cc Copyright (C) 2009-2012: Leslie Greengard and Zydrunas Gimbutas
cc Contact: greengard@cims.nyu.edu
cc 
cc This software is being released under a modified FreeBSD license
cc (see COPYING in home directory). 
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c
c     This is the first release of the FMM3D library, together with
c     associated subroutines, which computes N-body interactions
c     governed by the Laplace or Helmholtz equations.
c  
c
        program testlap
        implicit real *8 (a-h,o-z)
        real *8     source(3,1 000 000)
        complex *16 charge(1 000 000)
        complex *16 dipstr(1 000 000)
        real *8     dipvec(3,1 000 000)
        complex *16 pot(1 000 000)
        complex *16 fld(3,1 000 000)
c       
        complex *16 pot2(1 000 000)
        complex *16 fld2(3,1 000 000)
c       
        real *8     target(3,2 000 000)
        complex *16 pottarg(2 000 000)
        complex *16 fldtarg(3,2 000 000)
c
        complex *16 ptemp,ftemp(3)
c       
        complex *16 ima
        data ima/(0.0d0,1.0d0)/
c
        character*80 inf
        real *8 fmmtime(5)
c
        done=1
        pi=4*atan(done)
c
c     Initialize simple printing routines. The parameters to prini
c     define output file numbers using standard Fortran conventions.
c
c     Calling prini(6,13) causes printing to the screen and to 
c     file fort.13.     
c
        call prini(6,13)
c
c
c     construct randomly located charge distribution on a unit sphere
c
c        nsource=16000
c        d=hkrand(0)
c        do i=1,nsource
c           theta=hkrand(0)*pi
c           phi=hkrand(0)*2*pi
c           source(1,i)=.5d0*cos(phi)*sin(theta)
c           source(2,i)=.5d0*sin(phi)*sin(theta)
c           source(3,i)=.5d0*cos(theta)
c        enddo
c
c     construct target distribution on a target unit sphere 
c
        call getarg(1,inf)
        write (*,*) inf
        ir = 114514
        open(unit=ir,file=inf)
        call coordread(ir, source, nsource)
c
        ntarget=nsource
        do i=1,ntarget
            target(1,i) = source(1,i)
            target(2,i) = source(2,i)
            target(3,i) = source(3,i)
        enddo
c
        call prinf('ntarget=*',ntarget,1)
c       
c     set precision flag
c
        iprec=2
        call prinf('iprec=*',iprec,1)
c       
c     set source type flags and output flags
c
        ifpot=1
        iffld=0
c
        ifcharge=1
        ifdipole=0
c
        ifpottarg=0
        iffldtarg=0
c
c       set source strengths
c
        if (ifcharge .eq. 1 ) then
           do i=1,nsource
              charge(i)=hkrand(0) + ima*hkrand(0)
           enddo
        endif
c
        if (ifdipole .eq. 1) then
           do i=1,nsource
              dipstr(i)=hkrand(0) + ima*hkrand(0)
              dipvec(1,i)=hkrand(0)
              dipvec(2,i)=hkrand(0)
              dipvec(3,i)=hkrand(0)
           enddo
        endif
c
c     initialize timing call
c
        do i=1,5
            call cpu_time(t1)
C$          t1=omp_get_wtime()
c     call FMM3D routine for sources and targets
            call lfmm3dparttarg(ier,iprec,
     $          nsource,source,ifcharge,charge,ifdipole,dipstr,dipvec,
     $          ifpot,pot,iffld,fld,ntarget,target,
     $          ifpottarg,pottarg,iffldtarg,fldtarg)
c       
            call cpu_time(t2)
C$            t2=omp_get_wtime()
            fmmtime(i)=t2-t1
        enddo
        call prin2('FMM main time=*',fmmtime,5)
c       
c
        call prinf('nsource=*',nsource,1)
        call prinf('ntarget=*',ntarget,1)
        call prin2('after fmm, time (sec)=*',t2-t1,1)
        call prin2('after fmm, speed (points+targets/sec)=*',
     $     (nsource+ntarget)/(t2-t1),1)
c       
c     call direct calculation with subset of points to assess accuracy
c
c        m=min(nsource,100)
        m=nsource
c
c     ifprint=0 suppresses printing of source locations
c     ifprint=1 turns on printing of source locations
c
        ifprint=0
        if (ifprint .eq. 1) then
        call prin2('source=*',source,3*nsource)
        endif
c
c     ifprint=0 suppresses printing of potentials and fields
c     ifprint=1 turns on printing of potentials and fields
c
        ifprint=0
        if (ifprint .eq. 1) then
           if( ifpot.eq.1 ) call prin2('after fmm, pot=*',pot,2*m)
           if( iffld.eq.1 ) call prin2('after fmm, fld=*',fld,3*2*m)
        endif
c
c       for direct calculation, initialize pot2,fld2 arrays to zero.
c
        do i=1,nsource
           if (ifpot .eq. 1) pot2(i)=0
           if (iffld .eq. 1) then
              fld2(1,i)=0
              fld2(2,i)=0
              fld2(3,i)=0
           endif
        enddo
c        
c        t1=second()
        call cpu_time(t1)
C$        t1=omp_get_wtime()
c
C$OMP PARALLEL DO DEFAULT(SHARED)
C$OMP$PRIVATE(i,j,ptemp,ftemp) 
cccC$OMP$SCHEDULE(DYNAMIC)
cccC$OMP$NUM_THREADS(4) 
        do j=1,m
           do i=1,nsource       
              if( i .eq. j ) cycle
              if( ifcharge .eq. 1 ) then
                 call lpotfld3d(iffld,source(1,i),charge(i),
     $              source(1,j),ptemp,ftemp)
                 if (ifpot .eq. 1) pot2(j)=pot2(j)+ptemp
                 if (iffld .eq. 1) then
                    fld2(1,j)=fld2(1,j)+ftemp(1)
                    fld2(2,j)=fld2(2,j)+ftemp(2)
                    fld2(3,j)=fld2(3,j)+ftemp(3)
                 endif
              endif
              if (ifdipole .eq. 1) then
                 call lpotfld3d_dp(iffld,source(1,i),
     $              dipstr(i),dipvec(1,i),
     $              source(1,j),ptemp,ftemp)
                 if (ifpot .eq. 1) pot2(j)=pot2(j)+ptemp
                 if (iffld .eq. 1) then
                    fld2(1,j)=fld2(1,j)+ftemp(1)
                    fld2(2,j)=fld2(2,j)+ftemp(2)
                    fld2(3,j)=fld2(3,j)+ftemp(3)
                 endif
              endif
           enddo
        enddo
C$OMP END PARALLEL DO
c
c        t2=second()
        call cpu_time(t2)
C$        t2=omp_get_wtime()
c
c       ifprint=1 turns on printing of first m values of potential and field
c
        if (ifprint .eq. 1) then
           if( ifpot.eq.1 ) call prin2('directly, pot=*',pot2,2*m)
           if( iffld.eq.1 ) call prin2('directly, fld=*',fld2,3*2*m)
        endif
c
        call prin2('directly, estimated time (sec)=*',
     $     (t2-t1)*dble(nsource)/dble(m),1)
        call prin2('directly, estimated speed (points/sec)=*',
     $     m/(t2-t1),1)
c       
        if (ifpot .eq. 1)  then
           call l3derror(pot,pot2,m,aerr,rerr)
           call prin2('relative L2 error in potential=*',rerr,1)
        endif
c
        if (iffld .eq. 1) then
           call l3derror(fld,fld2,3*m,aerr,rerr)
           call prin2('relative L2 error in field=*',rerr,1)
        endif
c       
c
        do i=1,ntarget
           if (ifpottarg .eq. 1) pot2(i)=0
           if (iffldtarg .eq. 1) then
              fld2(1,i)=0
              fld2(2,i)=0
              fld2(3,i)=0
           endif
        enddo
c        
c        t1=second()
        call cpu_time(t1)
C$        t1=omp_get_wtime()
c
C$OMP PARALLEL DO DEFAULT(SHARED)
C$OMP$PRIVATE(i,j,ptemp,ftemp) 
cccC$OMP$SCHEDULE(DYNAMIC)
cccC$OMP$NUM_THREADS(4) 
        do j=1,m
        do i=1,nsource        
           if( ifcharge .eq. 1 ) then
              call lpotfld3d(iffldtarg,
     $           source(1,i),charge(i),target(1,j),
     $           ptemp,ftemp)
              if (ifpottarg .eq. 1) pot2(j)=pot2(j)+ptemp
              if (iffldtarg .eq. 1) then
                 fld2(1,j)=fld2(1,j)+ftemp(1)
                 fld2(2,j)=fld2(2,j)+ftemp(2)
                 fld2(3,j)=fld2(3,j)+ftemp(3)
              endif
           endif
           if (ifdipole .eq. 1) then
              call lpotfld3d_dp(iffldtarg,
     $           source(1,i),dipstr(i),dipvec(1,i),
     $           target(1,j),ptemp,ftemp)
              if (ifpottarg .eq. 1) pot2(j)=pot2(j)+ptemp
              if (iffldtarg .eq. 1) then
                 fld2(1,j)=fld2(1,j)+ftemp(1)
                 fld2(2,j)=fld2(2,j)+ftemp(2)
                 fld2(3,j)=fld2(3,j)+ftemp(3)
              endif
           endif
c
        enddo
        enddo
C$OMP END PARALLEL DO
c
c        t2=second()
        call cpu_time(t2)
C$        t2=omp_get_wtime()
c
c
c
        if (ifprint .eq. 1) then
           if( ifpottarg.eq.1 ) 
     $        call prin2('after fmm, pottarg=*',pottarg,2*m)
           if( iffldtarg.eq.1 ) 
     $        call prin2('after fmm, fldtarg=*',fldtarg,3*2*m)
        endif

        if (ifprint .eq. 1) then
           if (ifpottarg .eq. 1) 
     $        call prin2('directly, pottarg=*',pot2,2*m)
           if( iffldtarg.eq.1 ) 
     $        call prin2('directly, fldtarg=*',fld2,3*2*m)
        endif
c
        call prin2('directly, estimated time (sec)=*',
     $     (t2-t1)*dble(ntarget)/dble(m),1)
        call prin2('directly, estimated speed (targets/sec)=*',
     $     m/(t2-t1),1)
c       
        if (ifpottarg .eq. 1) then
           call l3derror(pottarg,pot2,m,aerr,rerr)
           call prin2('relative L2 error in target potential=*',rerr,1)
        endif
c
        if (iffldtarg .eq. 1) then
           call l3derror(fldtarg,fld2,3*m,aerr,rerr)
           call prin2('relative L2 error in target field=*',rerr,1)
        endif
c       
        stop
        end
c
c
c
c
        subroutine l3derror(pot1,pot2,n,ae,re)
        implicit real *8 (a-h,o-z)
c
c       evaluate absolute and relative errors
c
        complex *16 pot1(n),pot2(n)
c
        d=0
        a=0
c       
        do i=1,n
           d=d+abs(pot1(i)-pot2(i))**2
           a=a+abs(pot1(i))**2
        enddo
c       
c        d=d/n
        d=sqrt(d)
c        a=a/n
        a=sqrt(a)
c       
        ae=d
        re=d/a
c       
        return
        end
c
c
c
