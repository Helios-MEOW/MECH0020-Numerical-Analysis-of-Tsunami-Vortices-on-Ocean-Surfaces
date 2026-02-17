# Boundary conditions for no-slip and moving lid (streamfunction-vorticity)

**Executive summary:** For no-slip walls (u=v=0) and a moving lid (u=U,v=0), one sets \psi=constant on the wall (Dirichlet), then computes boundary vorticity \omega from Thom’s formula or ghost-point relations. For a stationary wall:  
\[ \omega_b = -2\frac{\psi_{\rm in} - \psi_{\rm wall}}{\Delta n^2},\]  
where \psi_wall=0, \Deltan is grid spacing normal to wall. For a moving wall (speed U tangent to wall):  
\[ \omega_b = -2\frac{\psi_{\rm in}-\psi_{\rm wall}}{\Delta n^2} - \frac{2U}{\Delta n}.\]  
These are derived using central differences and one-sided velocity BCs【116†L262-L265】.  

- **Derivation:** From $u=\partial\psi/\partial y$ and $v=−\partial\psi/\partial x$, enforce wall no-slip: $u=U_wall$, v=0 at boundary. E.g. top wall $(y=Y): \psi _wall=0$, and $\psi(i,N+1)=\psi(i,N-1)$ for symmetry. Discretize $\nabla^2 \psi$ at boundary to express $\omega$. For a fixed wall $U=0: \omega(i,N)= -2(\psi(i,N-1)-\psi(i,N))/\Delta y$. For lid: add $-2U/\Delta y$.  

- **Implementations:** Ghost-cell (extend $\psi$ outside domain), Thom’s formula (local formula as above), or Dirichlet $\psi$ with $\omega$ update. In spectral codes, enforce $\psi$ BC via sine transforms and adjust $\omega$ in physical space.  

- **Discrete formula (uniform grid \Delta):**  
  - Bottom: \[(v=0): \omega(i,1) = -2*(\psi(i,2)-\psi(i,1))/\Delta y^2\]
  - Top: \[(lid, u=U): \omega(i,Ny) = -2*(\psi(i,Ny-1)-\psi(i,Ny))/\Delta y^2 - 2*U/\Delta y\]
  - Left/Right walls \[(u=0): \omega(1,j) = -2*(\psi(2,j)-\psi(1,j))/\ ^2, \omega(Nx,j) = -2*(\psi(Nx-1,j)-\psi(Nx,j))/\Delta x^2\]  

- **Pseudocode:** (before Poisson solve)  
  ```matlab
  % \psi(:,1)=\psi(:,Ny)=\psi(1,:)=\psi(Nx,:)=0;  % Dirichlet
  for i=2:Nx-1
    % bottom wall (j=1)
    omega(i,1) = -2*(psi(i,2)-psi(i,1))/dy^2;
    % top lid (j=Ny) with speed U
    omega(i,Ny) = -2*(psi(i,Ny-1)-psi(i,Ny))/dy^2 - 2*U/dy;
  end
  for j=2:Ny-1
    % left wall (i=1), right wall (i=Nx)
    omega(1,j)  = -2*(psi(2,j)-psi(1,j))/dx^2;
    omega(Nx,j) = -2*(psi(Nx-1,j)-psi(Nx,j))/dx^2;
  end
  ```
- **Accuracy & pitfalls:** Thom’s formula is second-order accurate【116†L262-L265】. Issues: singular behavior at corners (infinite vorticity). Ensure $\psi=0$ on all walls for consistency. The Arakawa scheme remains valid if boundary $\omega$ is set consistently.  

```mermaid
flowchart LR
  A[Set $\psi=const$ on walls] --> B[Apply Thom’s formula for $\omega_b$]
  B --> C[Solve interior $\psi$ via Poisson]
  C --> D[Time-step vortex transport]
```

**Tags:** no-slip, lid-driven, Thom’s formula, vorticity-BC, CFD

**References:** Thom (1933)【116†L262-L265】; Woods (1954)【116†L271-L274】; Shankar & Deshpande (2000) *IJNMF*.