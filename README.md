# seges.github.identityserverautomation.apiresource
```
# Secret contains special chars which expand easily in bash if you are not careful
# Which is why it is tunnelled, seemingly unnecessarily though env...
name: AgroId Api Registration
on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy'
        type: environment
        required: true 
jobs:
  api_registration:
    runs-on: ubuntu-22.04
    environment: ${{ inputs.environment }}
    steps:
      - name: Prod Variables
        env:
          SECRET: ${{ secrets.AGROIDENTITY_PRODUCTION_CLIENTSECRET }}
        if: ${{ startsWith(inputs.environment, 'prod') }}
        run: |
          echo "IdentityserverUrl=https://login.agroid.dk" >> $GITHUB_ENV
          echo "IdentityServerClientId=urn:prod-octopus-client" >> $GITHUB_ENV
          echo "IdentityServerClientSecret=${SECRET}" >> $GITHUB_ENV
          echo "ResourceName=https://${{inputs.environment}}-foling-api.seges.dk/" >> $GITHUB_ENV
      - name: PreProd Variables
        env:
          SECRET: ${{ secrets.AGROIDENTITY_PREPRODUCTION_CLIENTSECRET }}
        if: ${{ !startsWith(inputs.environment, 'prod') }}
        run: |
          echo "IdentityserverUrl=https://si-agroid-identityserver.segestest.dk" >> $GITHUB_ENV
          echo "IdentityServerClientId=urn:si-octopus-client" >> $GITHUB_ENV
          echo "IdentityServerClientSecret=${SECRET}" >> $GITHUB_ENV
          echo "ResourceName=https://${{inputs.environment}}-foling-api.segeswebsites.net/" >> $GITHUB_ENV
      - name: Propercase Env
        run: |
          echo "PropercaseEnv=${{inputs.environment}}" >>${GITHUB_ENV}
      - name: Lowercase Env
        run: |
          echo "LowercaseEnv=${PropercaseEnv,,}" >>${GITHUB_ENV}
      - name: ApiRegistration
        uses: segesdk/seges.github.identityserverautomation.apiresource@master
        with:
          IdentityServerClientId: ${{env.IdentityServerClientId}}
          IdentityServerClientSecret: "${{env.IdentityServerClientSecret}}"
          IdentityserverUrl: ${{env.IdentityserverUrl}}
          ResourceEnvironment: ${{env.LowercaseEnv}}
          RoleFilter: GTALCNotSet*
          ResourceName: https://${{env.LowercaseEnv}}-foling-api.segeswebsites.net/
          ResourceReferenceName: ${{env.LowercaseEnv}}.foling
          ResourceDisplayName: ${{env.PropercaseEnv}} Foling
          ScopeNames: ${{env.LowercaseEnv}}.foling.default
          ScopeDisplayNames: ${{env.PropercaseEnv}} Foling Default
          UserClaims: role,name
   ```
