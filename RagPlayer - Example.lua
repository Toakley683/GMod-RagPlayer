--@name RagPlayer - Example
--@author toakley682
--@shared
--@include https://raw.githubusercontent.com/Jacbo1/Public-Starfall/main/SafeNet/safeNet.lua as SafeNet
--@include https://raw.githubusercontent.com/Toakley683/GMod-RagPlayer/main/ragdoll_player_library.lua as RagPlayer

require( "RagPlayer" )

if SERVER then
    
    local Punch = Ability( "Punch" )
    
    Punch.Hand = false
    
    Punch:OnEquip( function( Ability, Ragdoll )
        
        // On Ability Equip
        
    end)
    
    Punch:OnUnequip( function( Ability, Ragdoll )
        
        // On Ability Unequip
        
    end)
    
    Punch:OnPress( function( Ability, Ragdoll )
        
        // When ability button is initially activated
        
        Ability.Hand = !Ability.Hand
        
        if Ability.Hand == true then
            
            Ragdoll.RHand:applyForceCenter( Ragdoll.Facing:getRight() * 10000 )
            
        else
            
            Ragdoll.LHand:applyForceCenter( Ragdoll.Facing:getRight() * 10000 )
            
        end
        
    end)
    
    Punch:OnRelease( function( Ability, Ragdoll )
        
        // When ability button is released
        
    end)
    
    Punch:OnActive( function( Ability, Ragdoll )
        
        // Called every tick ability button is held
        
    end)
    
    Punch:OnTick( function( Ability, Ragdoll )
        
        // Called every tick ability is equiped
        
    end)
    
    local Abilities = { Punch, Ability( "Ability2" ), Ability( "Ability3" ), Ability( "Ability4" ) }
    
    local Rag = RagPlayer( owner(), Abilities )
    
end
