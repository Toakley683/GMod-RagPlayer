--@name ragdoll_player_library
--@author toakley682, Ax25
--@shared
--@include https://raw.githubusercontent.com/Jacbo1/Public-Starfall/main/SafeNet/safeNet.lua as SafeNet

local net = require( "SafeNet" )

// Ability Ideas //

--[[

--  Grabbing ( Holding something )
--  Grabbing ( Holding on to something / Climbing )
--  Shield
--  Turret

]]

// Other Ideas //

--[[

--  Hands move while walking/running ( Priority 1 )

]]


function AwaitUntil( Await, Callback, UID )
    
    local TimerName = "__AwaitUnitl:" .. UID
    
    if timer.exists( TimerName ) then timer.remove( TimerName ) end
    
    timer.create( TimerName, 0.1, 0, function()
        
        if Await() == false then return end
        Callback()
        timer.remove( TimerName )
        
    end)
    
end

function NumberToBase(n,b)
    n = math.floor(n)
    if not b or b == 10 then return tostring(n) end
    local digits = "0123456789abcdefghijklmnopqrstuvwxyz"
    local t = {}
    local sign = ""
    if n < 0 then
        sign = "-"
    n = -n
    end
    repeat
        local d = (n % b) + 1
        n = math.floor(n / b)
        table.insert(t, 1, digits:sub(d,d))
    until n == 0
    return sign .. table.concat(t,"")
end

function PadStart( String1, Length, String2 )
    
    if string.len( String1 ) >= Length then return String1 end
    
    local LenDiff = Length - string.len( String1 )
    local TString = string.explode( "", String1 )
    
    for I = 1, LenDiff do
        table.insert( TString, 1, String2 )
    end
    
    return table.concat( TString, "" )
    
end

function StringToHashColor( String )
    
    local Hash = 0
    
    for Index, CharCode in string.utf8codes( String ) do
        
        Hash = CharCode + ( ( bit.lshift( Hash, 5 ) ) - Hash )
        
    end
    
    local C = "#"
    
    for I = 0, 2 do
        
        local V = bit.band( bit.rshift( Hash, ( I * 8 ) ), 0xff )
        
        C = C .. PadStart( NumberToBase( V, 16 ), 2, "0" )
        
    end
    
    return Color( C )
    
end

if CLIENT then
    
    safeNet.receive( "__RagdollInitialize", function()
        
        local Data = safeNet.readTable()
        
        local Ent = Data.RagdollEntity
        local Seat = Data.Seat
        
        hook.add( "NetworkEntityCreated", table.address( Data ) .. "AwaitRagdollNetwork", function( Entity )
            
            if Entity:entIndex() == Data.RagdollIndex then Ent = Entity end
            if Entity:entIndex() == Data.SeatIndex then Seat = Entity end
            
        end)
        
        AwaitUntil(
            function()
                
                if not Ent then return false end
                if not Ent:isValid() then return false end
                
                if not Seat then return false end
                if not Seat:isValid() then return false end
                
                return true
                                
            end,
            function()
                
                hook.remove( "NetworkEntityCreated", "AwaitRagdollNetwork" )
                
                if not Data.Player then Data.Player = owner() end
                
                local Player = hologram.create( chip():getPos(), Angle(), Data.Player:getModel(), Vector( 1 ) )
                
                Ent:setNoDraw( true )
                
                Player:setPlayerColor( Data.Player:getPlayerColor() )
                
                Player:setParent( Ent )
                Player:addEffects( 10 )
                Player:addEffects( 9 )
                
                local BInd = Ent:lookupBone( "ValveBiped.Bip01_Head1" )
                
                hook.add( "calcview", table.address( Data ) .. "CalcView", function( Pos, Ang, Fov, ZNear, ZFar )
                    
                    if BInd == nil then return end
                    
                    if not Ent then return end
                    if not Ent:isValid() then return end
                    
                    local HeadPos = Ent:getBonePosition( BInd )
                    
                    if not Seat then return end
                    if not Seat:isValid() then return end
                    
                    if Seat:getDriver() != player() then return end
                    
                    local CalcViewData = {}
                    
                    local Distance = 125
                    local HitNormalDistance = 2
                    
                    local Trace = trace.line( HeadPos, HeadPos - ( Ang:getForward() * 9999999 ), { Ent , Data.Player, Seat } )
                    
                    Trace.Distance = Trace.HitPos:getDistance( HeadPos )
                    
                    local Normal = Vector()
                    if Trace.Hit then Normal = ( Trace.HitNormal * HitNormalDistance ) end
                    
                    local CameraPosition = localToWorld( Vector( -math.clamp( Trace.Distance, 15, Distance ), 0, 0 ), Angle(), HeadPos, Ang )
                    
                    CalcViewData[ "origin" ] = ( CameraPosition + Normal )
                    CalcViewData[ "znear" ] = 0.5
                    
                    return CalcViewData
                    
                end)
                
                local W, H = render.getResolution()
                
                local WheelRadius = 512
                local WheelSelectionWidth = 128
                local WheelMarginAng = 4
                
                local SelectionFidelity = 8
                
                local AbilityPolys = {}
                
                // Create Polygons for selection wheels
                
                local AddedAng = ( 360 / table.count( Data.Abilities ) ) / 2
                
                local OpenKey = 2048
                local Keys = {}
                
                local SelectedID = 1
                local LastSelectedID = SelectedID
                
                local HashColors = {}
                
                for Index, Ability in ipairs( Data.Abilities ) do
                    
                    HashColors[ Index ] = StringToHashColor( Ability.AbilityName )
                    
                    local Poly = {}
                    
                    local Ang1 = ( 360 / table.count( Data.Abilities ) * ( Index + 0 ) ) + WheelMarginAng
                    
                    local X = ( W / 2 ) + math.cos( math.rad( Ang1 - AddedAng ) ) * ( WheelRadius - WheelSelectionWidth )
                    local Y = ( H / 2 ) + math.sin( math.rad( Ang1 - AddedAng ) ) * ( WheelRadius - WheelSelectionWidth )
                    
                    Poly[ table.count( Poly ) + 1 ] = { x=X, y=Y }
                    
                    for F = 0, SelectionFidelity do
                        
                        local A = 1 / SelectionFidelity * F
                        local FullA = 360 / table.count( Data.Abilities ) * ( Index + A )
                        
                        local X = ( W / 2 ) + math.cos( math.rad( FullA - AddedAng ) ) * WheelRadius
                        local Y = ( H / 2 ) + math.sin( math.rad( FullA - AddedAng ) ) * WheelRadius
                        
                        Poly[ table.count( Poly ) + 1 ] = { x=X, y=Y }
                        
                    end
                    
                    local Ang2 = ( 360 / table.count( Data.Abilities ) * ( Index + 1 ) ) - WheelMarginAng
                    
                    local X = ( W / 2 ) + math.cos( math.rad( Ang2 - AddedAng ) ) * ( WheelRadius - WheelSelectionWidth )
                    local Y = ( H / 2 ) + math.sin( math.rad( Ang2 - AddedAng ) ) * ( WheelRadius - WheelSelectionWidth )
                    
                    Poly[ table.count( Poly ) + 1 ] = { x=X, y=Y }
                    
                    AbilityPolys[ table.count( AbilityPolys ) + 1 ] = Poly
                    
                end
                
                hook.add( "KeyPress", table.address( Data ) .. ":KeyPress", function( Plr, Key )
                    
                    if Plr != player() then return end
                    Keys[ Key ] = true
                    
                end)
                
                hook.add( "KeyRelease", table.address( Data ) .. ":KeyRelease", function( Plr, Key )
                    
                    if Plr != player() then return end
                    Keys[ Key ] = false
                    
                end)
                
                local RadAddition = 48
                
                local LastWheelCur = 0
                local WheelDelay = 0.1
                
                hook.add( "mouseWheeled", table.address( Data ) .. ":Wheeled", function( Delta )
                    
                    if not Keys[ OpenKey ] then return end
                    
                    if LastWheelCur > timer.curtime() then return end
                    LastWheelCur = timer.curtime() + WheelDelay
                    
                    SelectedID = math.clamp( SelectedID - Delta, 0, table.count( AbilityPolys ) + 1 )
                    
                    if SelectedID > table.count( AbilityPolys ) then SelectedID = 1 end
                    if SelectedID < 1 then SelectedID = table.count( AbilityPolys ) end
                    
                end)
                
                local SelectorFont = render.createFont( "Akbar", 40, 900, true, false, true )
                
                hook.add( "drawhud", table.address( Data ) .. ":SelectorHud", function()
                    
                    if not Keys[ OpenKey ] then
                        
                        if LastSelectedID != SelectedID then
                            
                            LastSelectedID = SelectedID
                            
                            safeNet.start( Data.Index .. ":RagPlayer" )
                            safeNet.writeFloat( SelectedID )
                            safeNet.send()
                            
                        end
                        
                        return
                    end
                    
                    if not Seat then return end
                    if not Seat:isValid() then return end
                    
                    if Seat:getDriver() != player() then return end
                    
                    render.setFont( SelectorFont )
                    
                    local CursorA = 360 / table.count( AbilityPolys ) * SelectedID
                    
                    local CursorSize = 256
                    local CursorWidth = 64
                    
                    local DX = math.cos( math.rad( CursorA ) ) * CursorSize
                    local DY = math.sin( math.rad( CursorA ) ) * CursorSize
                    
                    local SideX = math.cos( math.rad( CursorA + 90 ) ) * CursorWidth
                    local SideY = math.sin( math.rad( CursorA + 90 ) ) * CursorWidth
                    
                    render.setColor( Color( 73, 138, 173 ) )
                    
                    render.drawTriangle( 
                        ( W / 2 ) + DX, 
                        ( H / 2 ) + DY, 
                        ( W / 2 ) + SideX - ( DX / 3 ), 
                        ( H / 2 ) + SideY - ( DY / 3 ), 
                        ( W / 2 ) - SideX - ( DX / 3 ), 
                        ( H / 2 ) - SideY - ( DY / 3 ) 
                    )
                    
                    render.setColor( Color( 255, 255, 255 ) )
                    
                    for Index, Poly in ipairs( AbilityPolys ) do
                        
                        local Data = Data.Abilities[ Index ]
                        
                        local A = ( 360 / table.count( AbilityPolys ) * Index )
                        
                        local Rad = 0
                        local ColA = 150
                        
                        if Index == SelectedID then 
                            
                            ColA = 255
                            
                            Rad = RadAddition
                            
                        end
                        
                        local RotVec = Vector( math.cos( math.rad( A ) ) * Rad, math.sin( math.rad( A ) ) * Rad )
                        
                        local TextRotation = Matrix()
                        TextRotation:setTranslation( RotVec )
                        render.pushMatrix( TextRotation, false )
                        
                        local X = ( W / 2 ) + math.cos( math.rad( A ) ) * ( WheelRadius - WheelSelectionWidth )
                        local Y = ( H / 2 ) + math.sin( math.rad( A ) ) * ( WheelRadius - WheelSelectionWidth )
                        
                        local Col = HashColors[Index]:setA( ColA )
                        
                        render.setColor( Col )
                        render.drawPoly( Poly )
                        
                        local TW, TH = render.getTextSize( Data.AbilityName )
                        
                        render.popMatrix()
                        
                        local TextAngle = A + 90
                        
                        if 
                            TextAngle > 90 and
                            TextAngle <= 180
                        then
                            
                            TextAngle = TextAngle + 180
                            
                        end
                        
                        TextRotation:setAngles( Angle( 0, TextAngle, 0 ) )
                        TextRotation:setTranslation( 
                            Vector( 
                                X, 
                                Y
                            ) + RotVec
                            - Angle( 0, TextAngle, 0 ):getForward() * ( TW / 2 )
                            + Angle( 0, TextAngle, 0 ):getRight() * ( TH / 2 )
                        )
                        
                        render.pushMatrix( TextRotation, false )
                        
                        render.setColor( Color( 255, 255, 255 ) )
                        render.drawSimpleText(
                            0,
                            0,
                            Data.AbilityName
                        )
                        
                        render.popMatrix()
                        
                    end
                    
                end)
                
                local LastDriver = nil
                
                hook.add( "think", table.address( Data ) .. "UpdatePlayermodel", function()
                    
                    if not Data.Player or not Data.Player:isValid() then 
                        
                        if Seat:getDriver() != nil then
                            
                            Data.Player = Seat:getDriver()
                            
                        end
                        
                        return
                    end
                    
                    Player:setModel( Data.Player:getModel() )
                    
                    if not Seat then return end
                    if type( Seat ) != "Vehicle" then return end
                    if not Seat:isValid() then return end
                    
                    if Seat:getDriver():isValid() then
                        
                        try( function()
                            
                            Seat:getDriver():setNoDraw( true )
                            
                        end)
                        
                        LastDriver = Seat:getDriver()
                        
                    else
                        
                        if not LastDriver then return end
                        
                        try( function()
                            
                            LastDriver:setNoDraw( false )
                            
                        end)
                        
                        LastDriver = nil
                        
                    end
                    
                    hook.add( "Removed", table.address( Data ) .. "ChipRemoved", function()
                        
                        if not LastDriver then return end
                        
                        LastDriver:setNoDraw( false )
                        
                    end)
                    
                end)
                                
            end,
            "__RagdollInitialize"
        )
        
    end)
    
else
    
    function TraceDir( Start, Direction, Distance, Filter, Mask, ColGroup, IgnoreWorld )
        
        local T = trace.line( Start, Start + Direction * Distance, Filter, Mask, ColGroup, IgnoreWorld )
        
        T.Distance = T.HitPos:getDistance( Start )
        
        return T
        
    end
    
    RagPlayer = class( "RagPlayer" )
    Ability = class( "Ability" )
    AbilityCard = class( "AbilityCard" )
    
    local InitializedPlayers = {}
    
    local RagPlayers = {}
    
    hook.add( "ClientInitialized", "__ClientInit", function( Player )
        
        InitializedPlayers[ table.count( InitializedPlayers ) + 1 ] = Player
        
        for Index, Ragdoll in ipairs( RagPlayers ) do
            
            Ragdoll:ClientInit( Player )
            
        end
        
    end)
    
    function RagPlayer:initialize( Player, AbilEnt )
        
        RagPlayers[ table.count( RagPlayers ) + 1 ] = self
        
        self.Index = table.address( self )
        
        self.Abilities = AbilEnt
        
        self.Keys = {}
        self.Controls = {}
        self.IgnoredEnts = {}
        
        self.ForwardSpeed = 0
        self.WalkIncrement = 0
        
        self.AbilityID = 1
        self.SelectedAbility = nil
        
        self.Player = Player
        self.Origin = chip():getPos()
        
        self.Sprinting = false
        
        self.JumpStartTime = 0
        
        self.FlySpeed = 0
        self.FlySpeedAcceleration = 100
        self.MaxFlySpeed = 2500
        
        self.FlyControlTime = 0.25
        
        self.FIncrease = 0.5
        
        self.MaxSpeed = 2
        self.MaxSprintSpeed = 5
        
        self.MovingRagdollTraceDist = 40
        self.IdleRagdollTraceDist = 45
        
        self.CanMoveCurtime = 0
        self.FallTimer = 1
        
        self.Facing = Angle()
        
        self.Ragdoll = prop.createRagdoll( "models/Barney.mdl", true )
        self.RagdollBones = {}
        
        self.TurnSpeed = 2
        
        self.PhysBones = {}
        
        self.Pelvis = self:GetPhysBoneByName( "ValveBiped.Bip01_Pelvis" )
        self.Spine = self:GetPhysBoneByName( "ValveBiped.Bip01_Spine2" )
        self.Head = self:GetPhysBoneByName( "ValveBiped.Bip01_Head1" )
        
        self.LHand = self:GetPhysBoneByName( "ValveBiped.Bip01_L_Hand" )
        self.RHand = self:GetPhysBoneByName( "ValveBiped.Bip01_R_Hand" )
        
        self.LFoot = self:GetPhysBoneByName( "ValveBiped.Bip01_L_Foot" )
        self.RFoot = self:GetPhysBoneByName( "ValveBiped.Bip01_R_Foot" )
        
        self.LCalf = self:GetPhysBoneByName( "ValveBiped.Bip01_L_Calf" )
        self.RCalf = self:GetPhysBoneByName( "ValveBiped.Bip01_R_Calf" )
        
        if self.Abilities then
            
            if table.count( self.Abilities ) then
                
                self.SelectedAbility = self.Abilities[ self.AbilityID ]
                self.SelectedAbility:__OnEquip( self )
                
            end
            
        end
        
        self.Size = self.Ragdoll:obbSize()
        
        local Center = self.Origin + Vector( 0, 0, self.Size[3] / 2 )
        
        self:PhysBonesLoop( function( _, PhysBone )
            
            local LocalPos = worldToLocal( PhysBone:getPos(), Angle(), self.Ragdoll:getPos(), self.Ragdoll:getAngles() )
            local NewPos = localToWorld( LocalPos, Angle(), Center, Angle() )
            
            PhysBone:addGameFlags( FVPHYSICS.NO_PLAYER_PICKUP )
            PhysBone:enableMotion( true )
            PhysBone:setPos( NewPos )
            
        end, function()
            
            self.Ragdoll:setColor( Color( 0, 0, 0, 0 ) )
            self.Ragdoll:setFrozen( false )
            
            self.Seat = prop.createSeat( Center, Angle(), "models/nova/airboat_seat.mdl", true )
            
            self.Seat:setCollisionGroup( 20 )
            self.Seat:setColor( Color( 0, 0, 0, 0 ) )
            self.Seat:setDrawShadow( false )
            
        end)
        
        self.Emitter = prop.create( chip():getPos(), self.Ragdoll:getAngles(), "models/hunter/plates/plate.mdl", true )
        self.Emitter:setSolid( false )
        self.Emitter:setColor( Color( 0, 0, 0, 0 ) )
        self.Emitter:setDrawShadow( false )
        
        self:PopulateControls()
        self:OnFrozen()
        
        net.receive( self.Index .. ":RagPlayer", function( _, Player )
            
            if Player != self.Driver then return end
            
            self.SelectedAbility:__OnUnequip( self )
            
            self.AbilityID = net.readFloat()
            self.SelectedAbility = self.Abilities[ self.AbilityID ]
            
            self.SelectedAbility:__OnEquip( self )
            
        end)
        
        hook.add( "tick", table.address( self ) .. ":Tick", function()
            
            self:Check()
            
        end)
        
        hook.add( "KeyPress", table.address( self ) .. ":KeyPress", function( Plr, Key )
            
            self:KeyPress( Plr, Key )
            
        end)
        
        hook.add( "KeyRelease", table.address( self ) .. ":KeyRelease", function( Plr, Key )
            
            self:KeyRelease( Plr, Key )
            
        end)
        
    end
    
    function RagPlayer:PhysBonesLoop( CB, FinishedLoop )
        
        local Finished = false
        
        for PhysObjID = 0, self.Ragdoll:getPhysicsObjectCount() do
            
            local E = self.Ragdoll:getPhysicsObjectNum( PhysObjID )
            
            if PhysObjID == self.Ragdoll:getPhysicsObjectCount() then Finished = true end
            
            if not E then continue end
            if not E:isValid() then continue end
            
            CB( PhysObjID, E )
            
        end
        
        if FinishedLoop == nil then return end
        
        AwaitUntil(
            function()
                
                if Finished == false then return false end
                
                return true
                
            end,
            FinishedLoop,
            "AwaitFinishedLoop"
        )
        
    end
    
    function RagPlayer:GetPhysBoneByName( Bone )
        
        local BInd = self.Ragdoll:lookupBone( Bone )
        local PhysBoneID = self.Ragdoll:translateBoneToPhysBone( BInd )
        local PhysBone = self.Ragdoll:getPhysicsObjectNum( PhysBoneID )
        
        self.PhysBones[ table.count( self.PhysBones ) + 1 ] = PhysBone
        
        return PhysBone
        
    end
    
    function RagPlayer:OnFrozen()
        
        self:PhysBonesLoop( function( _, PhysBone )
            
            if not PhysBone:isValid() then return end
            
            PhysBone:addGameFlags( FVPHYSICS.NO_PLAYER_PICKUP )
            PhysBone:addGameFlags( FVPHYSICS.HEAVY_OBJECT )
            PhysBone:enableMotion( true )
            
        end)
        
    end
    
    function RagPlayer:Check()
        
        if not self.Seat then return end
        if not self.Seat:isValid() then return end
        
        self:Tick()
        
        self.Driver = self.Seat:getDriver()
        
        if self.Driver:isValid() then
            
            self.LastDriver = self.Driver
                        
            if self.Driver:getEyeAngles() == Angle() then return end
            
            self.RagdollTraceDist = self.MovingRagdollTraceDist
            
            if self.Driver:isHUDActive() != true then
                
                // Enable hud
                enableHud( self.Driver, true )
                
            end
            
            self.Facing = Angle( math.clamp( self.Driver:getEyeAngles()[1], -90, 35 ), self.Driver:getEyeAngles()[2] + 90, 0 )
            self.Seat:setCollisionGroup( 10 )
            
            // Make ragdoll face the aim direction
            
            local YawDir = math.angleDifference( self.Facing[2], self.Head:getAngles()[2] - 90 ) * self.TurnSpeed
            
            local Dif = 35
            
            local UHeadPos = localToWorld( Vector( 0, -Dif, 0 ), Angle(), self.Head:getPos(), self.Head:getAngles() )
            local UPelvisPos = localToWorld( Vector( 0, -Dif, 0 ), Angle(), self.Pelvis:getPos(), Angle( 0, self.Pelvis:getAngles()[2], 0 ) )
            
            local UFacingPos = localToWorld( Vector( Dif, 0, 0 ), Angle(), self.Head:getPos(), Angle( self.Facing[1], self.Facing[2] - 90, 0 ) )
            local UPelviFacingPos = localToWorld( Vector( Dif, 0, 0 ), Angle(), self.Pelvis:getPos(), Angle( 0, self.Facing[2] - 90, 0 ) )
            
            local UDir = ( ( UFacingPos - UHeadPos ) * 12 )
            local UPelvisDir = ( ( UPelviFacingPos - UPelvisPos ) * 12 )
            
            self:WalkTick()
            
            self.Head:addAngleVelocity( -self.Head:getAngleVelocity() / 2 )
            
            self.Head:applyForceOffset( UDir, UHeadPos )
            self.Pelvis:applyForceOffset( UPelvisDir, UHeadPos )
            
        else
            
            self.Facing = Angle( 0, self.Head:getAngles()[2] - 90, 0 )
            
            self.RagdollTraceDist = self.IdleRagdollTraceDist
            
            self.Keys = {}
            self.Sprinting = false
            
            self:IdleTick()
            
        end
        
    end
    
    function RagPlayer:IdleTick()
        
        for Index, PhysBone in ipairs( self.PhysBones ) do
            
            // Wakeup all bones
            PhysBone:wake()
            
        end
        
    end
    
    function RagPlayer:KeyPress( Plr, Key )
        
        if Plr != self.Driver then return end
        
        self.Keys[ Key ] = true
        
        for KeyID, KeyData in pairs( self.Controls ) do
            
            if KeyID != Key then continue end
            
            KeyData.OnPress()
            
            if KeyData.OnTick == nil then return end
            // Setup hook to do OnTick()
            
            local HookName = table.address( KeyData ) .. ":KeyID:" .. KeyID
            
            hook.add( "tick", HookName, function() KeyData.OnTick() end)
            return
            
        end
        
    end
    
    function RagPlayer:KeyRelease( Plr, Key )
        
        if Plr != self.Driver and Plr != self.LastDriver then return end
        
        self.Keys[ Key ] = false
        
        for KeyID, KeyData in pairs( self.Controls ) do
            
            if KeyID != Key then continue end
            
            KeyData.OnRelease()
            
            // Remove the hook for OnTick()
            
            local HookName = table.address( KeyData ) .. ":KeyID:" .. KeyID
            
            hook.remove( "tick", HookName )
            return
            
        end
        
    end
    
    function RagPlayer:RegisterNewKey( KeyID, OnPress, OnRelease, OnTick )
        
        self.Controls[ KeyID ] = {}
        
        self.Controls[ KeyID ][ "Key" ] = KeyID
        
        self.Controls[ KeyID ][ "OnPress" ] = OnPress
        self.Controls[ KeyID ][ "OnRelease" ] = OnRelease
        self.Controls[ KeyID ][ "OnTick" ] = OnTick
        
    end
    
    function RagPlayer:RagdollPlayer()
        
        self.CanMoveCurtime = timer.curtime() + self.FallTimer
        
    end
    
    function RagPlayer:PopulateControls()
        
        local RocketSound = sound.create( self.Emitter, "vehicles/fast_windloop1.wav" )
        
        self:RegisterNewKey( 
            2, --[ IN_JUMP ]--
            function() // OnPress()
                
                self.FlySpeed = 0
                
                if timer.curtime() <= self.CanMoveCurtime then return end
                self.JumpStartTime = timer.curtime()
                
            end,
            function() // OnRelease()
                
                if RocketSound:isPlaying() then RocketSound:stop() end
                
                local TimeDif = timer.curtime() - self.JumpStartTime
                self.JumpStartTime = 0
                
                if timer.curtime() <= self.CanMoveCurtime then return end
                if self.FlyControlTime < TimeDif then return end
                
                if self.RagdollTrace.Hit then
                    
                    self:RagdollPlayer()
                    self.Head:applyForceCenter( ( self.Facing + Angle( 0, -90, 0 ) ):getForward() * 120000 )
                    
                end
                
            end,
            function() // OnTick()
                
                if timer.curtime() - self.JumpStartTime > self.FlyControlTime then
                    
                    RocketSound:setPitch( 100 )
                    RocketSound:setSoundLevel( 75 )
                    
                    if not RocketSound:isPlaying() then RocketSound:play() end
                    
                    // Is flying if (IN_JUMP) held for 1 second
                    
                    self:RagdollPlayer()
                    self.FlySpeed = math.clamp( self.FlySpeed + self.FlySpeedAcceleration, 0, self.MaxFlySpeed )
                    
                    RocketSound:setVolume( 1 / self.MaxFlySpeed * self.FlySpeed )
                    
                    local FlightSpeed = self.FlySpeed
                    if self.Keys[ 131072 ] then FlightSpeed = self.FlySpeed * 2 end
                    
                    self.LHand:applyForceCenter( ( self.Facing + Angle( 0, -90, 0 ) ):getForward() * FlightSpeed )
                    self.RHand:applyForceCenter( ( self.Facing + Angle( 0, -90, 0 ) ):getForward() * FlightSpeed )
                    
                end
                
            end
        )
        
        self:RegisterNewKey( 
            1, --[ IN_ATTACK ]--
            function() // OnPress()
                
                if self.SelectedAbility == nil then return end
                
                self.SelectedAbility:__OnPress( self )
                
            end,
            function() // OnRelease()
                
                if self.SelectedAbility == nil then return end
                
                self.SelectedAbility:__OnRelease( self )
                
            end,
            function() // OnTick()
                
                if self.SelectedAbility == nil then return end
                
                self.SelectedAbility:__OnActive( self )
                
            end
        )
        
    end
    
    function RagPlayer:Tick()
        
        for Index, PhysBone in ipairs( self.PhysBones ) do
            
            if not PhysBone:isMoveable() then
                
                self:OnFrozen()
                return
                
            end
            
        end
        
        self.SelectedAbility:__OnTick( self )
        
        self.LFoot:setBuoyancyRatio( 0 )
        self.RFoot:setBuoyancyRatio( 0 )
        self.Pelvis:setBuoyancyRatio( 0 )
        self.Head:setBuoyancyRatio( 0 )
        
        local LowestFootZ = math.min(
            self.LFoot:getPos()[3],
            self.RFoot:getPos()[3]
        )
        
        self.BasePos = self.Ragdoll:getPos()
        self.BasePos:setZ( LowestCalfZ )
        
        self.LowFootPos = self.Ragdoll:getPos()
        self.LowFootPos:setZ( LowestFootZ )
        
        if not self.Seat then return end
        if not self.Seat:isValid() then return end
        
        self.Seat:setCollisionGroup( 20 )
        self.Seat:setPos( self.Ragdoll:getPos() )
        self.Seat:setAngles( Angle() )
        
        self.Emitter:setPos( self.Ragdoll:getPos() )
        
        self:MovementTick()
        
    end
    
    function RagPlayer:WalkTick() 
        
        // Walking input check
        
        local MSpeed = self.MaxSpeed
        if self.Sprinting then MSpeed = self.MaxSprintSpeed end
        
        if self.Keys[ 131072 ] then
            
            // IN_SPEED ( Default: Shift )
            self.Sprinting = true
            
        else
            
            self.Sprinting = false
            
        end
        
        if self.Keys[ 8 ] then
            
            // IN_FORWARD ( Default: W )
            self.ForwardSpeed = math.clamp( self.ForwardSpeed + self.FIncrease, 0, MSpeed )
            
        end
        
        if self.Keys[ 16 ] then
            
            // IN_BACK ( Default: S )
            self.ForwardSpeed = math.clamp( self.ForwardSpeed - self.FIncrease, -MSpeed, 0 )
            
        end
        
        if not self.Keys[ 8 ] and not self.Keys[ 16 ] then
            
            // NOT( IN_BACK && IN_FORWARD )
            
            if self.ForwardSpeed > 0 then
                
                self.ForwardSpeed = math.clamp( self.ForwardSpeed - self.FIncrease, 0, MSpeed )
                
            else
                
                self.ForwardSpeed = math.clamp( self.ForwardSpeed + self.FIncrease, -MSpeed, 0 ) 
                
            end
            
        end
        
        // Check for if ragdolled
        
        if self.ForwardSpeed == 0 then return end
        
        if timer.curtime() <= self.CanMoveCurtime then return end
        
        if self.RTraceDistRatio == nil then return end
        
        // Walking Logic
        
        self.WalkIncrement = self.WalkIncrement + ( self.ForwardSpeed / 20 )
        
        self.ViewYaw = Angle( 0, self.Facing[2] - 90, 0 )
        
        local LOrigin = self.Ragdoll:getPos() + Vector( 0, 0, -40 )
        
        local StepHeight = 15
        
        local ElevL = ( self.ViewYaw:getUp() * ( 12 + math.cos( self.WalkIncrement / 2 ) * StepHeight ) )
        local ElevR = ( self.ViewYaw:getUp() * ( 12 + math.sin( self.WalkIncrement / 2 ) * StepHeight ) )
        
        local CalfInc = 14
        
        self.WalkPos = ( self.ViewYaw:getForward() * math.sin( self.WalkIncrement ) * 27 )
        
        local LTargetDiff = 
            (
                LOrigin -
                self.WalkPos -
                self.ViewYaw:getRight() * 6 +
                ElevL
            )
        
        local RTargetDiff = 
            (
                LOrigin +
                self.WalkPos +
                self.ViewYaw:getRight() * 6 + 
                ElevR
            )
        
        self.LFoot:applyForceCenter(
            (
                -self.LFoot:getVelocity() * 2
                + ( LTargetDiff - self.LFoot:getPos() ) * 85
            ) / 2
        )
        
        self.RFoot:applyForceCenter(
            (
                -self.RFoot:getVelocity() * 2
                + ( RTargetDiff - self.RFoot:getPos() ) * 85
            ) / 2
        )
        
    end
    
    function RagPlayer:MovementTick()
        
        self.ViewYaw = Angle( 0, self.Facing[2] - 90, 0 )
        
        local IGN = {}
        
        table.add( IGN, { self.Ragdoll, self.Seat, self.Emitter } )
        table.add( IGN, self.IgnoredEnts )
        
        self.RagdollTrace = TraceDir( self.Ragdoll:getPos(), Vector( 0, 0, -1 ), self.RagdollTraceDist, IGN )
        self.FallTrace = TraceDir( self.Ragdoll:getPos(), Vector( 0, 0, -1 ), 70, IGN )
        
        if not self.FallTrace.Hit or self.Ragdoll:getWaterLevel() > 0 then
            self:RagdollPlayer()
        end
        
        local FootAverage = ( self.LFoot:getPos() + self.RFoot:getPos() ) / 2
        
        // Standing in prop velocity inheritance
        
        local PVel = self.Pelvis:getVelocity() / 3 * 2
        
        self.RTraceDistance = self.RagdollTrace.Distance
        
        self.RTraceDistRatio = 1 - ( self.RTraceDistance / self.RagdollTraceDist )
        self.RTraceDistSubDist = self.RTraceDistance - ( self.LastRTraceDistance or 0 )
        
        local StandingVelocity = Vector()
        
        if self.RagdollTrace.Entity then
            
            if self.RagdollTrace.Entity:isValid() then
                
                StandingVelocity = self.RagdollTrace.Entity:getVelocity() * self.Pelvis:getMass() + Vector( PVel[1] * self.RTraceDistRatio, PVel[2] * self.RTraceDistRatio, 0 )
                
            end
            
        end
        
        // Inertia canceling
        
        self.Pelvis:applyForceCenter( StandingVelocity )
        
        self.LastRTraceDistance = self.RTraceDistance
        
        if timer.curtime() <= self.CanMoveCurtime then
            self.RTraceDistance = 20
            return 
        end
        
        self.Pelvis:applyForceCenter(
            Vector(
                -PVel[1] * self.RTraceDistRatio,
                -PVel[2] * self.RTraceDistRatio,
                self.RTraceDistRatio * ( 45 - self.RTraceDistSubDist * 5 )
            ) * 100
        )
        
        self.Pelvis:applyForceCenter(
            (
                (
                    ( self.ViewYaw:getForward() * self.ForwardSpeed * 24 ) +
                    ( FootAverage - self.Pelvis:getPos() ):setZ( 0 )
                )*
                100
            ) * self.RTraceDistRatio * 2.5
        )
        
        self.Head:applyForceCenter(
            -physenv.getGravity() * 0.6
        )
        
        self.Spine:applyForceCenter(
            -physenv.getGravity() * 0.6
        )
        
    end
    
    function RagPlayer:ClientInit( Player )
        
        AwaitUntil(
            function()
                
                if not self.Seat then return false end
                if not self.Seat:isValid() then return false end
                
                if not self.Ragdoll then return false end
                if not self.Ragdoll:isValid() then return false end
                
                return true
                
            end,
            function()
                
                local Data = {}
                
                Data[ "Index" ] = self.Index
                Data[ "RagdollIndex" ] = self.Ragdoll:entIndex()
                Data[ "RagdollEntity" ] = self.Ragdoll
                Data[ "Seat" ] = self.Seat
                Data[ "SeatIndex" ] = self.Seat:entIndex()
                Data[ "Player" ] = self.Player
                
                local AbilTable = {}
                
                for Index, Ability in ipairs( self.Abilities ) do
                    
                    AbilTable[ table.count( AbilTable ) + 1 ] = Ability:asTable()
                    
                end
                
                Data[ "Abilities" ] = AbilTable
                
                safeNet.start( "__RagdollInitialize" )
                safeNet.writeTable( Data )
                safeNet.send( Player )
                
            end,
            "__RagdollInitialize:" .. Player:getSteamID()
        )
        
    end
    
    function Ability:asTable()
        
        local Data = {}
        
        Data.AbilityName = self.AbilityName
        
        return Data
        
    end
    
    function Ability:initialize( AbilityName )
        
        self.AbilityName = AbilityName
        
        self.PressFunc = function() end
        self.EquipFunc = function() end
        self.UnequipFunc = function() end
        self.ReleaseFunc = function() end
        self.TickFunc = function() end
        self.ActiveTick = function() end
        
    end
    
    function Ability:__OnPress( Ragdoll ) self.PressFunc( self, Ragdoll ) end
    function Ability:__OnEquip( Ragdoll ) self.EquipFunc( self, Ragdoll ) end
    function Ability:__OnUnequip( Ragdoll ) self.UnequipFunc( self, Ragdoll ) end
    function Ability:__OnRelease( Ragdoll ) self.ReleaseFunc( self, Ragdoll ) end
    function Ability:__OnTick( Ragdoll ) self.TickFunc( self, Ragdoll ) end
    function Ability:__OnActive( Ragdoll ) self.ActiveTick( self, Ragdoll ) end
    
    function Ability:OnPress( Func ) self.PressFunc = Func end
    function Ability:OnEquip( Func ) self.EquipFunc = Func end
    function Ability:OnUnequip( Func ) self.UnequipFunc = Func end
    function Ability:OnRelease( Func ) self.ReleaseFunc = Func end
    function Ability:OnTick( Func ) self.TickFunc = Func end
    function Ability:OnActive( Func ) self.ActiveTick = Func end
    
end
