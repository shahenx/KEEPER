serpent = require("serpent")
lgi = require ('lgi')
redis = require('redis')
database = Redis.connect('127.0.0.1', 6379)
notify = lgi.require('Notify')
notify.init ("Telegram updates")
chats = {}
day = 86400
bot_id = 366410400   --ايــدي البــوت
sudo_users = {334262610,420839465}   -- ايدي المطورين
  -----------------------------------------------------------------------------------------------
                                     -- start functions --
  -----------------------------------------------------------------------------------------------
function is_sudo(msg)
  local var = false
  for k,v in pairs(sudo_users) do
    if msg.sender_user_id_ == v then
      var = true
    end
  end
  return var
end
-----------------------------------------------------------------------------------------------
function is_admin(user_id)
    local var = false
	local hashs =  'bot:admins:'
    local admin = database:sismember(hashs, user_id)
	 if admin then
	    var = true
	 end
  for k,v in pairs(sudo_users) do
    if user_id == v then
      var = true
    end
  end
    return var
end
-----------------------------------------------------------------------------------------------
function is_vip_group(gp_id)
    local var = false
	local hashs =  'bot:vipgp:'
    local vip = database:sismember(hashs, gp_id)
	 if vip then
	    var = true
	 end
    return var
end
-----------------------------------------------------------------------------------------------
function is_owner(user_id, chat_id)
    local var = false
    local hash =  'bot:owners:'..chat_id
    local owner = database:sismember(hash, user_id)
	local hashs =  'bot:admins:'
    local admin = database:sismember(hashs, user_id)
	 if owner then
	    var = true
	 end
	 if admin then
	    var = true
	 end
    for k,v in pairs(sudo_users) do
    if user_id == v then
      var = true
    end
	end
    return var
end
-----------------------------------------------------------------------------------------------
function is_mod(user_id, chat_id)
    local var = false
    local hash =  'bot:mods:'..chat_id
    local mod = database:sismember(hash, user_id)
	local hashs =  'bot:admins:'
    local admin = database:sismember(hashs, user_id)
	local hashss =  'bot:owners:'..chat_id
    local owner = database:sismember(hashss, user_id)
	 if mod then
	    var = true
	 end
	 if owner then
	    var = true
	 end
	 if admin then
	    var = true
	 end
    for k,v in pairs(sudo_users) do
    if user_id == v then
      var = true
    end
	end
    return var
end
-----------------------------------------------------------------------------------------------
function is_banned(user_id, chat_id)
    local var = false
	local hash = 'bot:banned:'..chat_id
    local banned = database:sismember(hash, user_id)
	 if banned then
	    var = true
	 end
    return var
end
-----------------------------------------------------------------------------------------------
function is_muted(user_id, chat_id)
    local var = false
	local hash = 'bot:muted:'..chat_id
    local banned = database:sismember(hash, user_id)
	 if banned then
	    var = true
	 end
    return var
end
-----------------------------------------------------------------------------------------------
function is_gbanned(user_id)
    local var = false
	local hash = 'bot:gbanned:'
    local banned = database:sismember(hash, user_id)
	 if banned then
	    var = true
	 end
    return var
end
-----------------------------------------------------------------------------------------------
local function check_filter_words(msg, value)
  local hash = 'bot:filters:'..msg.chat_id_
  if hash then
    local names = database:hkeys(hash)
    local text = ''
    for i=1, #names do
	   if string.match(value:lower(), names[i]:lower()) and not is_mod(msg.sender_user_id_, msg.chat_id_)then
	     local id = msg.id_
         local msgs = {[0] = id}
         local chat = msg.chat_id_
        delete_msg(chat,msgs)
       end
    end
  end
end
-----------------------------------------------------------------------------------------------
function resolve_username(username,cb)
  tdcli_function ({
    ID = "SearchPublicChat",
    username_ = username
  }, cb, nil)
end
  -----------------------------------------------------------------------------------------------
function changeChatMemberStatus(chat_id, user_id, status)
  tdcli_function ({
    ID = "ChangeChatMemberStatus",
    chat_id_ = chat_id,
    user_id_ = user_id,
    status_ = {
      ID = "ChatMemberStatus" .. status
    },
  }, dl_cb, nil)
end
  -----------------------------------------------------------------------------------------------
function getInputFile(file)
  if file:match('/') then
    infile = {ID = "InputFileLocal", path_ = file}
  elseif file:match('^%d+$') then
    infile = {ID = "InputFileId", id_ = file}
  else
    infile = {ID = "InputFilePersistentId", persistent_id_ = file}
  end

  return infile
end
  -----------------------------------------------------------------------------------------------
function del_all_msgs(chat_id, user_id)
  tdcli_function ({
    ID = "DeleteMessagesFromUser",
    chat_id_ = chat_id,
    user_id_ = user_id
  }, dl_cb, nil)
end
  -----------------------------------------------------------------------------------------------
function getChatId(id)
  local chat = {}
  local id = tostring(id)
  
  if id:match('^-100') then
    local channel_id = id:gsub('-100', '')
    chat = {ID = channel_id, type = 'channel'}
  else
    local group_id = id:gsub('-', '')
    chat = {ID = group_id, type = 'group'}
  end
  
  return chat
end
  -----------------------------------------------------------------------------------------------
function chat_leave(chat_id, user_id)
  changeChatMemberStatus(chat_id, user_id, "Left")
end
  -----------------------------------------------------------------------------------------------
function from_username(msg)
   function gfrom_user(extra,result,success)
   if result.username_ then
   F = result.username_
   else
   F = 'nil'
   end
    return F
   end
  local username = getUser(msg.sender_user_id_,gfrom_user)
  return username
end
  -----------------------------------------------------------------------------------------------
function chat_kick(chat_id, user_id)
  changeChatMemberStatus(chat_id, user_id, "Kicked")
end
  -----------------------------------------------------------------------------------------------
function do_notify (user, msg)
  local n = notify.Notification.new(user, msg)
  n:show ()
end
  -----------------------------------------------------------------------------------------------
local function getParseMode(parse_mode)  
  if parse_mode then
    local mode = parse_mode:lower()
  
    if mode == 'markdown' or mode == 'md' then
      P = {ID = "TextParseModeMarkdown"}
    elseif mode == 'html' then
      P = {ID = "TextParseModeHTML"}
    end
  end
  return P
end
  -----------------------------------------------------------------------------------------------
local function getMessage(chat_id, message_id,cb)
  tdcli_function ({
    ID = "GetMessage",
    chat_id_ = chat_id,
    message_id_ = message_id
  }, cb, nil)
end
-----------------------------------------------------------------------------------------------
function sendContact(chat_id, reply_to_message_id, disable_notification, from_background, reply_markup, phone_number, first_name, last_name, user_id)
  tdcli_function ({
    ID = "SendMessage",
    chat_id_ = chat_id,
    reply_to_message_id_ = reply_to_message_id,
    disable_notification_ = disable_notification,
    from_background_ = from_background,
    reply_markup_ = reply_markup,
    input_message_content_ = {
      ID = "InputMessageContact",
      contact_ = {
        ID = "Contact",
        phone_number_ = phone_number,
        first_name_ = first_name,
        last_name_ = last_name,
        user_id_ = user_id
      },
    },
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
function sendPhoto(chat_id, reply_to_message_id, disable_notification, from_background, reply_markup, photo, caption)
  tdcli_function ({
    ID = "SendMessage",
    chat_id_ = chat_id,
    reply_to_message_id_ = reply_to_message_id,
    disable_notification_ = disable_notification,
    from_background_ = from_background,
    reply_markup_ = reply_markup,
    input_message_content_ = {
      ID = "InputMessagePhoto",
      photo_ = getInputFile(photo),
      added_sticker_file_ids_ = {},
      width_ = 0,
      height_ = 0,
      caption_ = caption
    },
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
function getUserFull(user_id,cb)
  tdcli_function ({
    ID = "GetUserFull",
    user_id_ = user_id
  }, cb, nil)
end
-----------------------------------------------------------------------------------------------
function vardump(value)
  print(serpent.block(value, {comment=false}))
end
-----------------------------------------------------------------------------------------------
function dl_cb(arg, data)
end
-----------------------------------------------------------------------------------------------
local function send(chat_id, reply_to_message_id, disable_notification, text, disable_web_page_preview, parse_mode)
  local TextParseMode = getParseMode(parse_mode)
  
  tdcli_function ({
    ID = "SendMessage",
    chat_id_ = chat_id,
    reply_to_message_id_ = reply_to_message_id,
    disable_notification_ = disable_notification,
    from_background_ = 1,
    reply_markup_ = nil,
    input_message_content_ = {
      ID = "InputMessageText",
      text_ = text,
      disable_web_page_preview_ = disable_web_page_preview,
      clear_draft_ = 0,
      entities_ = {},
      parse_mode_ = TextParseMode,
    },
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
function sendaction(chat_id, action, progress)
  tdcli_function ({
    ID = "SendChatAction",
    chat_id_ = chat_id,
    action_ = {
      ID = "SendMessage" .. action .. "Action",
      progress_ = progress or 100
    }
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
function changetitle(chat_id, title)
  tdcli_function ({
    ID = "ChangeChatTitle",
    chat_id_ = chat_id,
    title_ = title
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
function edit(chat_id, message_id, reply_markup, text, disable_web_page_preview, parse_mode)
  local TextParseMode = getParseMode(parse_mode)
  tdcli_function ({
    ID = "EditMessageText",
    chat_id_ = chat_id,
    message_id_ = message_id,
    reply_markup_ = reply_markup,
    input_message_content_ = {
      ID = "InputMessageText",
      text_ = text,
      disable_web_page_preview_ = disable_web_page_preview,
      clear_draft_ = 0,
      entities_ = {},
      parse_mode_ = TextParseMode,
    },
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
function setphoto(chat_id, photo)
  tdcli_function ({
    ID = "ChangeChatPhoto",
    chat_id_ = chat_id,
    photo_ = getInputFile(photo)
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
function add_user(chat_id, user_id, forward_limit)
  tdcli_function ({
    ID = "AddChatMember",
    chat_id_ = chat_id,
    user_id_ = user_id,
    forward_limit_ = forward_limit or 50
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
function unpinmsg(channel_id)
  tdcli_function ({
    ID = "UnpinChannelMessage",
    channel_id_ = getChatId(channel_id).ID
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
local function blockUser(user_id)
  tdcli_function ({
    ID = "BlockUser",
    user_id_ = user_id
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
local function unblockUser(user_id)
  tdcli_function ({
    ID = "UnblockUser",
    user_id_ = user_id
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
local function getBlockedUsers(offset, limit)
  tdcli_function ({
    ID = "GetBlockedUsers",
    offset_ = offset,
    limit_ = limit
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
function delete_msg(chatid,mid)
  tdcli_function ({
  ID="DeleteMessages", 
  chat_id_=chatid, 
  message_ids_=mid
  },
  dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
function chat_del_user(chat_id, user_id)
  changeChatMemberStatus(chat_id, user_id, 'Editor')
end
-----------------------------------------------------------------------------------------------
function getChannelMembers(channel_id, offset, filter, limit)
  if not limit or limit > 200 then
    limit = 200
  end
  tdcli_function ({
    ID = "GetChannelMembers",
    channel_id_ = getChatId(channel_id).ID,
    filter_ = {
      ID = "ChannelMembers" .. filter
    },
    offset_ = offset,
    limit_ = limit
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
function getChannelFull(channel_id)
  tdcli_function ({
    ID = "GetChannelFull",
    channel_id_ = getChatId(channel_id).ID
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
local function channel_get_bots(channel,cb)
local function callback_admins(extra,result,success)
    limit = result.member_count_
    getChannelMembers(channel, 0, 'Bots', limit,cb)
    end
  getChannelFull(channel,callback_admins)
end
-----------------------------------------------------------------------------------------------
local function getInputMessageContent(file, filetype, caption)
  if file:match('/') then
    infile = {ID = "InputFileLocal", path_ = file}
  elseif file:match('^%d+$') then
    infile = {ID = "InputFileId", id_ = file}
  else
    infile = {ID = "InputFilePersistentId", persistent_id_ = file}
  end

  local inmsg = {}
  local filetype = filetype:lower()

  if filetype == 'animation' then
    inmsg = {ID = "InputMessageAnimation", animation_ = infile, caption_ = caption}
  elseif filetype == 'audio' then
    inmsg = {ID = "InputMessageAudio", audio_ = infile, caption_ = caption}
  elseif filetype == 'document' then
    inmsg = {ID = "InputMessageDocument", document_ = infile, caption_ = caption}
  elseif filetype == 'photo' then
    inmsg = {ID = "InputMessagePhoto", photo_ = infile, caption_ = caption}
  elseif filetype == 'sticker' then
    inmsg = {ID = "InputMessageSticker", sticker_ = infile, caption_ = caption}
  elseif filetype == 'video' then
    inmsg = {ID = "InputMessageVideo", video_ = infile, caption_ = caption}
  elseif filetype == 'voice' then
    inmsg = {ID = "InputMessageVoice", voice_ = infile, caption_ = caption}
  end

  return inmsg
end

-----------------------------------------------------------------------------------------------
function send_file(chat_id, type, file, caption,wtf)
local mame = (wtf or 0)
  tdcli_function ({
    ID = "SendMessage",
    chat_id_ = chat_id,
    reply_to_message_id_ = mame,
    disable_notification_ = 0,
    from_background_ = 1,
    reply_markup_ = nil,
    input_message_content_ = getInputMessageContent(file, type, caption),
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
function getUser(user_id, cb)
  tdcli_function ({
    ID = "GetUser",
    user_id_ = user_id
  }, cb, nil)
end
-----------------------------------------------------------------------------------------------
function pin(channel_id, message_id, disable_notification) 
   tdcli_function ({ 
     ID = "PinChannelMessage", 
     channel_id_ = getChatId(channel_id).ID, 
     message_id_ = message_id, 
     disable_notification_ = disable_notification 
   }, dl_cb, nil) 
end 
-----------------------------------------------------------------------------------------------
function tdcli_update_callback(data)
	-------------------------------------------
  if (data.ID == "UpdateNewMessage") then
    local msg = data.message_
    --vardump(data)
    local d = data.disable_notification_
    local chat = chats[msg.chat_id_]
	-------------------------------------------
	if msg.date_ < (os.time() - 30) then
       return false
    end
	-------------------------------------------
	if not database:get("bot:enable:"..msg.chat_id_) and not is_admin(msg.sender_user_id_, msg.chat_id_) then
      return false
    end
    -------------------------------------------
      if msg and msg.send_state_.ID == "MessageIsSuccessfullySent" then
	  --vardump(msg)
	   function get_mymsg_contact(extra, result, success)
             --vardump(result)
       end
	      getMessage(msg.chat_id_, msg.reply_to_message_id_,get_mymsg_contact)
         return false 
      end
    --------- ANTI FLOOD -------------------
	local hash = 'flood:max:'..msg.chat_id_
    if not database:get(hash) then
        floodMax = 5
    else
        floodMax = tonumber(database:get(hash))
    end

    local hash = 'flood:time:'..msg.chat_id_
    if not database:get(hash) then
        floodTime = 3
    else
        floodTime = tonumber(database:get(hash))
    end
    if not is_mod(msg.sender_user_id_, msg.chat_id_) then
        local hashse = 'anti-flood:'..msg.chat_id_
        if not database:get(hashse) then
                if not is_mod(msg.sender_user_id_, msg.chat_id_) then
                    local hash = 'flood:'..msg.sender_user_id_..':'..msg.chat_id_..':msg-num'
                    local msgs = tonumber(database:get(hash) or 0)
                    if msgs > (floodMax - 1) then
                        local user = msg.sender_user_id_
                        local chat = msg.chat_id_
                        local channel = msg.chat_id_
						 local user_id = msg.sender_user_id_
						 local banned = is_banned(user_id, msg.chat_id_)
                         if banned then
						local id = msg.id_
        				local msgs = {[0] = id}
       					local chat = msg.chat_id_
       						       del_all_msgs(msg.chat_id_, msg.sender_user_id_)
						    else
						 local id = msg.id_
                         local msgs = {[0] = id}
                         local chat = msg.chat_id_
		                chat_kick(msg.chat_id_, msg.sender_user_id_)
						 del_all_msgs(msg.chat_id_, msg.sender_user_id_)
						user_id = msg.sender_user_id_
						local bhash =  'bot:banned:'..msg.chat_id_
                        database:sadd(bhash, user_id)
                           send(msg.chat_id_, msg.id_, 1, '🚀￤ الايــدي  *('..msg.sender_user_id_..')* \n\n🚀￤  التكــــرار ممنــــوع 🔒\n\n🚀￤ تــم ✔ طــردك♩', 1, 'md')
					  end
                    end
                    database:setex(hash, floodTime, msgs+1)
                end
        end
	end
	-------------------------------------------
	database:incr("bot:allmsgs")
	if msg.chat_id_ then
      local id = tostring(msg.chat_id_)
      if id:match('-100(%d+)') then
        if not database:sismember("bot:groups",msg.chat_id_) then
            database:sadd("bot:groups",msg.chat_id_)
        end
        elseif id:match('^(%d+)') then
        if not database:sismember("bot:userss",msg.chat_id_) then
            database:sadd("bot:userss",msg.chat_id_)
        end
        else
        if not database:sismember("bot:groups",msg.chat_id_) then
            database:sadd("bot:groups",msg.chat_id_)
        end
     end
    end
	-------------------------------------------
    -------------* MSG TYPES *-----------------
   if msg.content_ then
   	if msg.reply_markup_ and  msg.reply_markup_.ID == "ReplyMarkupInlineKeyboard" then
		print("Send INLINE KEYBOARD")
	msg_type = 'MSG:Inline'
	-------------------------
    elseif msg.content_.ID == "MessageText" then
	text = msg.content_.text_
		print("SEND TEXT")
	msg_type = 'MSG:Text'
	-------------------------
	elseif msg.content_.ID == "MessagePhoto" then
	print("SEND PHOTO")
	if msg.content_.caption_ then
	caption_text = msg.content_.caption_
	end
	msg_type = 'MSG:Photo'
	-------------------------
	elseif msg.content_.ID == "MessageChatAddMembers" then
	print("NEW ADD TO GROUP")
	msg_type = 'MSG:NewUserAdd'
	-------------------------
	elseif msg.content_.ID == "MessageChatJoinByLink" then
		print("JOIN TO GROUP")
	msg_type = 'MSG:NewUserLink'
	-------------------------
	elseif msg.content_.ID == "MessageSticker" then
		print("SEND STICKER")
	msg_type = 'MSG:Sticker'
	-------------------------
	elseif msg.content_.ID == "MessageAudio" then
		print("SEND MUSIC")
	if msg.content_.caption_ then
	caption_text = msg.content_.caption_
	end
	msg_type = 'MSG:Audio'
	-------------------------
	elseif msg.content_.ID == "MessageVoice" then
		print("SEND VOICE")
	if msg.content_.caption_ then
	caption_text = msg.content_.caption_
	end
	msg_type = 'MSG:Voice'
	-------------------------
	elseif msg.content_.ID == "MessageVideo" then
		print("SEND VIDEO")
	if msg.content_.caption_ then
	caption_text = msg.content_.caption_
	end
	msg_type = 'MSG:Video'
	-------------------------
	elseif msg.content_.ID == "MessageAnimation" then
		print("SEND GIF")
	if msg.content_.caption_ then
	caption_text = msg.content_.caption_
	end
	msg_type = 'MSG:Gif'
	-------------------------
	elseif msg.content_.ID == "MessageLocation" then
		print("SEND LOCATION")
	if msg.content_.caption_ then
	caption_text = msg.content_.caption_
	end
	msg_type = 'MSG:Location'
	-------------------------
	elseif msg.content_.ID == "MessageChatJoinByLink" or msg.content_.ID == "MessageChatAddMembers" then
	msg_type = 'MSG:NewUser'
	-------------------------
	elseif msg.content_.ID == "MessageContact" then
		print("SEND CONTACT")
	if msg.content_.caption_ then
	caption_text = msg.content_.caption_
	end
	msg_type = 'MSG:Contact'
	-------------------------
	end
   end
    -------------------------------------------
    -------------------------------------------
    if ((not d) and chat) then
      if msg.content_.ID == "MessageText" then
        do_notify (chat.title_, msg.content_.text_)
      else
        do_notify (chat.title_, msg.content_.ID)
      end
    end
  -----------------------------------------------------------------------------------------------
                                     -- end functions --
  -----------------------------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------
                                     -- start code --
  -----------------------------------------------------------------------------------------------
  -------------------------------------- Process mod --------------------------------------------
  -----------------------------------------------------------------------------------------------
  
  -------------------------------------------------------------------------------------------------------
  -------------------------------------------------------------------------------------------------------
  --------------------------******** START MSG CHECKS ********-------------------------------------------
  -------------------------------------------------------------------------------------------------------
  -------------------------------------------------------------------------------------------------------
if is_banned(msg.sender_user_id_, msg.chat_id_) then
        local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
		  chat_kick(msg.chat_id_, msg.sender_user_id_)
		  return 
end
if is_muted(msg.sender_user_id_, msg.chat_id_) then
        local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
          delete_msg(chat,msgs)
		  return 
end
if is_gbanned(msg.sender_user_id_) then
        local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
		  chat_kick(msg.chat_id_, msg.sender_user_id_)
		   return 
end	
if database:get('bot:muteall'..msg.chat_id_) and not is_mod(msg.sender_user_id_, msg.chat_id_) then
        local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
        return 
end
    database:incr('user:msgs'..msg.chat_id_..':'..msg.sender_user_id_)
	database:incr('group:msgs'..msg.chat_id_)
if msg.content_.ID == "MessagePinMessage" then
  if database:get('pinnedmsg'..msg.chat_id_) and database:get('bot:pin:mute'..msg.chat_id_) then
   send(msg.chat_id_, msg.id_, 1, '`', 1, 'md')
   unpinmsg(msg.chat_id_)
   local pin_id = database:get('pinnedmsg'..msg.chat_id_)
         pin(msg.chat_id_,pin_id,0)
   end
end
if database:get('bot:viewget'..msg.sender_user_id_) then 
    if not msg.forward_info_ then
		send(msg.chat_id_, msg.id_, 1, '`', 1, 'md')
		database:del('bot:viewget'..msg.sender_user_id_)
	else
		send(msg.chat_id_, msg.id_, 1, 'Your Post Views:\n> '..msg.views_..' View!', 1, 'md')
        database:del('bot:viewget'..msg.sender_user_id_)
	end
end
if msg_type == 'MSG:Photo' then
   --vardump(msg)
 if not is_mod(msg.sender_user_id_, msg.chat_id_) then
if msg.forward_info_ then
if database:get('bot:forward:mute'..msg.chat_id_) then
	if msg.forward_info_.ID == "MessageForwardedFromUser" or msg.forward_info_.ID == "MessageForwardedPost" then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   end
     if database:get('bot:photo:mute'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
       delete_msg(chat,msgs)
          return 
   end
   if caption_text then
      check_filter_words(msg, caption_text)
   if caption_text:match("[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm].[Mm][Ee]") or caption_text:match("[Tt][Ll][Gg][Rr][Mm].[Mm][Ee]") then
   if database:get('bot:links:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   if caption_text:match("@") or msg.content_.entities_[0].ID and msg.content_.entities_[0].ID == "MessageEntityMentionName" then
   if database:get('bot:tag:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   if caption_text:match("#") then
   if database:get('bot:hashtag:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   if caption_text:match("[Hh][Tt][Tt][Pp][Ss]://") or caption_text:match("[Hh][Tt][Tt][Pp]://") or caption_text:match(".[Ii][Rr]") or caption_text:match(".[Cc][Oo][Mm]") or caption_text:match(".[Oo][Rr][Gg]") or caption_text:match(".[Ii][Nn][Ff][Oo]") or caption_text:match("[Ww][Ww][Ww].") or caption_text:match(".[Tt][Kk]") then
   if database:get('bot:webpage:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   if caption_text:match("[\216-\219][\128-\191]") then
   if database:get('bot:arabic:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   if caption_text:match("[ASDFGHJKLQWERTYUIOPZXCVBNMasdfghjklqwertyuiopzxcvbnm]") then
   if database:get('bot:english:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   end
   end
  elseif msg_type == 'MSG:Inline' then
   if not is_mod(msg.sender_user_id_, msg.chat_id_) then
    if database:get('bot:inline:mute'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
       delete_msg(chat,msgs)
          return 
   end
   end
  elseif msg_type == 'MSG:Sticker' then
   if not is_mod(msg.sender_user_id_, msg.chat_id_) then
  if database:get('bot:sticker:mute'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
       delete_msg(chat,msgs)
          return 
   end
   end
elseif msg_type == 'MSG:NewUserLink' then
  if database:get('bot:tgservice:mute'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
       delete_msg(chat,msgs)
          return 
   end
   function get_welcome(extra,result,success)
    if database:get('welcome:'..msg.chat_id_) then
        text = database:get('welcome:'..msg.chat_id_)
    else
        text = '*نــــــورتُِّ {firstname} 🌚🎋*'
    end
    local text = text:gsub('{firstname}',(result.first_name_ or ''))
    local text = text:gsub('{lastname}',(result.last_name_ or ''))
    local text = text:gsub('{username}',(result.username_ or ''))
         send(msg.chat_id_, msg.id_, 1, text, 1, 'html')
   end
	  if database:get("bot:welcome"..msg.chat_id_) then
        getUser(msg.sender_user_id_,get_welcome)
      end
elseif msg_type == 'MSG:NewUserAdd' then
  if database:get('bot:tgservice:mute'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
       delete_msg(chat,msgs)
          return 
   end
      --vardump(msg)
   if msg.content_.members_[0].username_ and msg.content_.members_[0].username_:match("[Bb][Oo][Tt]$") then
      if database:get('bot:bots:mute'..msg.chat_id_) and not is_mod(msg.content_.members_[0].id_, msg.chat_id_) then
		 chat_kick(msg.chat_id_, msg.content_.members_[0].id_)
		 return false
	  end
   end
   if is_banned(msg.content_.members_[0].id_, msg.chat_id_) then
		 chat_kick(msg.chat_id_, msg.content_.members_[0].id_)
		 return false
   end
   if database:get("bot:welcome"..msg.chat_id_) then
    if database:get('welcome:'..msg.chat_id_) then
        text = database:get('welcome:'..msg.chat_id_)
    else
        text = '*نــــــورتُِّ {firstname} 🌚🎋*'
    end
    local text = text:gsub('{firstname}',(msg.content_.members_[0].first_name_ or ''))
    local text = text:gsub('{lastname}',(msg.content_.members_[0].last_name_ or ''))
    local text = text:gsub('{username}',('@'..msg.content_.members_[0].username_ or ''))
         send(msg.chat_id_, msg.id_, 1, text, 1, 'html')
   end
elseif msg_type == 'MSG:Contact' then
 if not is_mod(msg.sender_user_id_, msg.chat_id_) then
if msg.forward_info_ then
if database:get('bot:forward:mute'..msg.chat_id_) then
	if msg.forward_info_.ID == "MessageForwardedFromUser" or msg.forward_info_.ID == "MessageForwardedPost" then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   end
  if database:get('bot:contact:mute'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
       delete_msg(chat,msgs)
          return 
   end
   end
elseif msg_type == 'MSG:Audio' then
 if not is_mod(msg.sender_user_id_, msg.chat_id_) then
if msg.forward_info_ then
if database:get('bot:forward:mute'..msg.chat_id_) then
	if msg.forward_info_.ID == "MessageForwardedFromUser" or msg.forward_info_.ID == "MessageForwardedPost" then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   end
  if database:get('bot:music:mute'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
       delete_msg(chat,msgs)
          return 
   end
   if caption_text then
      check_filter_words(msg, caption_text)
   if caption_text:match("[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm].[Mm][Ee]") or caption_text:match("[Tt][Ll][Gg][Rr][Mm].[Mm][Ee]") then
   if database:get('bot:links:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
 if caption_text:match("@") or msg.content_.entities_[0].ID == "MessageEntityMentionName" then
   if database:get('bot:tag:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
  	if caption_text:match("#") then
   if database:get('bot:hashtag:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   	if caption_text:match("[Hh][Tt][Tt][Pp][Ss]://") or caption_text:match("[Hh][Tt][Tt][Pp]://") or caption_text:match(".[Ii][Rr]") or caption_text:match(".[Cc][Oo][Mm]") or caption_text:match(".[Oo][Rr][Gg]") or caption_text:match(".[Ii][Nn][Ff][Oo]") or caption_text:match("[Ww][Ww][Ww].") or caption_text:match(".[Tt][Kk]") then
   if database:get('bot:webpage:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
     if caption_text:match("[\216-\219][\128-\191]") then
    if database:get('bot:arabic:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   if caption_text:match("[ASDFGHJKLQWERTYUIOPZXCVBNMasdfghjklqwertyuiopzxcvbnm]") then
   if database:get('bot:english:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   end
   end
elseif msg_type == 'MSG:Voice' then
 if not is_mod(msg.sender_user_id_, msg.chat_id_) then
if msg.forward_info_ then
if database:get('bot:forward:mute'..msg.chat_id_) then
	if msg.forward_info_.ID == "MessageForwardedFromUser" or msg.forward_info_.ID == "MessageForwardedPost" then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   end
  if database:get('bot:voice:mute'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
       delete_msg(chat,msgs)
          return  
   end
   if caption_text then
      check_filter_words(msg, caption_text)
  if caption_text:match("[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm].[Mm][Ee]") or caption_text:match("[Tt].[Mm][Ee]") or caption_text:match("[Tt][Ll][Gg][Rr][Mm].[Mm][Ee]") then
   if database:get('bot:links:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
  if caption_text:match("@") then
  if database:get('bot:tag:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   	if caption_text:match("#") then
   if database:get('bot:hashtag:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
	if caption_text:match("[Hh][Tt][Tt][Pp][Ss]://") or caption_text:match("[Hh][Tt][Tt][Pp]://") or caption_text:match(".[Ii][Rr]") or caption_text:match(".[Cc][Oo][Mm]") or caption_text:match(".[Oo][Rr][Gg]") or caption_text:match(".[Ii][Nn][Ff][Oo]") or caption_text:match("[Ww][Ww][Ww].") or caption_text:match(".[Tt][Kk]") then
   if database:get('bot:webpage:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   	 if caption_text:match("[\216-\219][\128-\191]") then
    if database:get('bot:arabic:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   if caption_text:match("[ASDFGHJKLQWERTYUIOPZXCVBNMasdfghjklqwertyuiopzxcvbnm]") then
   if database:get('bot:english:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   end
   end
elseif msg_type == 'MSG:Location' then
 if not is_mod(msg.sender_user_id_, msg.chat_id_) then
if msg.forward_info_ then
if database:get('bot:forward:mute'..msg.chat_id_) then
	if msg.forward_info_.ID == "MessageForwardedFromUser" or msg.forward_info_.ID == "MessageForwardedPost" then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   end
  if database:get('bot:location:mute'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
       delete_msg(chat,msgs)
          return  
   end
   if caption_text then
      check_filter_words(msg, caption_text)
   if caption_text:match("[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm].[Mm][Ee]") or caption_text:match("[Tt].[Mm][Ee]") or caption_text:match("[Tt][Ll][Gg][Rr][Mm].[Mm][Ee]") then
   if database:get('bot:links:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   if caption_text:match("@") or msg.content_.entities_[0].ID and msg.content_.entities_[0].ID == "MessageEntityMentionName" then
   if database:get('bot:tag:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   	if caption_text:match("#") then
   if database:get('bot:hashtag:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   	if caption_text:match("[Hh][Tt][Tt][Pp][Ss]://") or caption_text:match("[Hh][Tt][Tt][Pp]://") or caption_text:match(".[Ii][Rr]") or caption_text:match(".[Cc][Oo][Mm]") or caption_text:match(".[Oo][Rr][Gg]") or caption_text:match(".[Ii][Nn][Ff][Oo]") or caption_text:match("[Ww][Ww][Ww].") or caption_text:match(".[Tt][Kk]") then
   if database:get('bot:webpage:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   	if caption_text:match("[\216-\219][\128-\191]") then
   if database:get('bot:arabic:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   if caption_text:match("[ASDFGHJKLQWERTYUIOPZXCVBNMasdfghjklqwertyuiopzxcvbnm]") then
   if database:get('bot:english:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   end
   end
elseif msg_type == 'MSG:Video' then
 if not is_mod(msg.sender_user_id_, msg.chat_id_) then
if msg.forward_info_ then
if database:get('bot:forward:mute'..msg.chat_id_) then
	if msg.forward_info_.ID == "MessageForwardedFromUser" or msg.forward_info_.ID == "MessageForwardedPost" then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   end
  if database:get('bot:video:mute'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
       delete_msg(chat,msgs)
          return  
   end
   if caption_text then
      check_filter_words(msg, caption_text)
  if caption_text:match("[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm].[Mm][Ee]") or caption_text:match("[Tt].[Mm][Ee]") or caption_text:match("[Tt][Ll][Gg][Rr][Mm].[Mm][Ee]") then
   if database:get('bot:links:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   if caption_text:match("@") or msg.content_.entities_[0].ID and msg.content_.entities_[0].ID == "MessageEntityMentionName" then
   if database:get('bot:tag:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   	if caption_text:match("#") then
   if database:get('bot:hashtag:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   	if caption_text:match("[Hh][Tt][Tt][Pp][Ss]://") or caption_text:match("[Hh][Tt][Tt][Pp]://") or caption_text:match(".[Ii][Rr]") or caption_text:match(".[Cc][Oo][Mm]") or caption_text:match(".[Oo][Rr][Gg]") or caption_text:match(".[Ii][Nn][Ff][Oo]") or caption_text:match("[Ww][Ww][Ww].") or caption_text:match(".[Tt][Kk]") then
   if database:get('bot:webpage:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   	if caption_text:match("[\216-\219][\128-\191]") then
   if database:get('bot:arabic:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   if caption_text:match("[ASDFGHJKLQWERTYUIOPZXCVBNMasdfghjklqwertyuiopzxcvbnm]") then
   if database:get('bot:english:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   end
   end
elseif msg_type == 'MSG:Gif' then
 if not is_mod(msg.sender_user_id_, msg.chat_id_) then
if msg.forward_info_ then
if database:get('bot:forward:mute'..msg.chat_id_) then
	if msg.forward_info_.ID == "MessageForwardedFromUser" or msg.forward_info_.ID == "MessageForwardedPost" then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   end
  if database:get('bot:gifs:mute'..msg.chat_id_) and not is_mod(msg.sender_user_id_, msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
       delete_msg(chat,msgs)
          return  
   end
   if caption_text then
   check_filter_words(msg, caption_text)
   if caption_text:match("[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm].[Mm][Ee]") or caption_text:match("[Tt].[Mm][Ee]") or caption_text:match("[Tt][Ll][Gg][Rr][Mm].[Mm][Ee]") then
   if database:get('bot:links:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   if caption_text:match("@") or msg.content_.entities_[0].ID and msg.content_.entities_[0].ID == "MessageEntityMentionName" then
   if database:get('bot:tag:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   	if caption_text:match("#") then
   if database:get('bot:hashtag:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
	if caption_text:match("[Hh][Tt][Tt][Pp][Ss]://") or caption_text:match("[Hh][Tt][Tt][Pp]://") or caption_text:match(".[Ii][Rr]") or caption_text:match(".[Cc][Oo][Mm]") or caption_text:match(".[Oo][Rr][Gg]") or caption_text:match(".[Ii][Nn][Ff][Oo]") or caption_text:match("[Ww][Ww][Ww].") or caption_text:match(".[Tt][Kk]") then
   if database:get('bot:webpage:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   	if caption_text:match("[\216-\219][\128-\191]") then
   if database:get('bot:arabic:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   if caption_text:match("[ASDFGHJKLQWERTYUIOPZXCVBNMasdfghjklqwertyuiopzxcvbnm]") then
   if database:get('bot:english:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   end	
   end
elseif msg_type == 'MSG:Text' then
 --vardump(msg)
    if database:get("bot:group:link"..msg.chat_id_) == 'انتظر 🐇🎋 ' and is_mod(msg.sender_user_id_, msg.chat_id_) then if text:match("(https://telegram.me/joinchat/%S+)") then 	 local glink = text:match("(https://telegram.me/joinchat/%S+)") local hash = "bot:group:link"..msg.chat_id_ database:set(hash,glink) 			 send(msg.chat_id_, msg.id_, 1, 'ضع رابط جديد', 1, 'md')
      end
   end
    function check_username(extra,result,success)
	 --vardump(result)
	local username = (result.username_ or '')
	local svuser = 'user:'..result.id_
	if username then
      database:hset(svuser, 'username', username)
    end
	if username and username:match("[Bb][Oo][Tt]$") then
      if database:get('bot:bots:mute'..msg.chat_id_) and not is_mod(result.id_, msg.chat_id_) then
		 chat_kick(msg.chat_id_, result.id_)
		 return false
		 end
	  end
   end
    getUser(msg.sender_user_id_,check_username)
   database:set('bot:editid'.. msg.id_,msg.content_.text_)
   if not is_mod(msg.sender_user_id_, msg.chat_id_) then
    check_filter_words(msg, text)
	if text:match("[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm].[Mm][Ee]") or 
text:match("[Tt].[Mm][Ee]") or
text:match("[Tt][Ll][Gg][Rr][Mm].[Mm][Ee]") then
     if database:get('bot:links:mute'..msg.chat_id_) then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
	if text then
     if database:get('bot:text:mute'..msg.chat_id_) then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
if msg.forward_info_ then
if database:get('bot:forward:mute'..msg.chat_id_) then
	if msg.forward_info_.ID == "MessageForwardedFromUser" or msg.forward_info_.ID == "MessageForwardedPost" then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   end
   if text:match("@") or msg.content_.entities_[0] and msg.content_.entities_[0].ID == "MessageEntityMentionName" then
   if database:get('bot:tag:mute'..msg.chat_id_) then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   	if text:match("#") then
      if database:get('bot:hashtag:mute'..msg.chat_id_) then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   	if text:match("[Hh][Tt][Tt][Pp][Ss]://") or text:match("[Hh][Tt][Tt][Pp]://") or text:match(".[Ii][Rr]") or text:match(".[Cc][Oo][Mm]") or text:match(".[Oo][Rr][Gg]") or text:match(".[Ii][Nn][Ff][Oo]") or text:match("[Ww][Ww][Ww].") or text:match(".[Tt][Kk]") then
      if database:get('bot:webpage:mute'..msg.chat_id_) then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   	if text:match("[\216-\219][\128-\191]") then
      if database:get('bot:arabic:mute'..msg.chat_id_) then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   	  if text:match("[ASDFGHJKLQWERTYUIOPZXCVBNMasdfghjklqwertyuiopzxcvbnm]") then
      if database:get('bot:english:mute'..msg.chat_id_) then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	  end
     end
    end
   end
  -------------------------------------------------------------------------------------------------------
  -------------------------------------------------------------------------------------------------------
  -------------------------------------------------------------------------------------------------------
  ---------------------------******** END MSG CHECKS ********--------------------------------------------
  -------------------------------------------------------------------------------------------------------
  -------------------------------------------------------------------------------------------------------
  if database:get('bot:cmds'..msg.chat_id_) and not is_mod(msg.sender_user_id_, msg.chat_id_) then
  return 
  else
    ------------------------------------ With Pattern -------------------------------------------
	if text:match("^[#!/]ping$") then
	   send(msg.chat_id_, msg.id_, 1, '_Pong_', 1, 'md')
	end
	-----------------------------------------------------------------------------------------------
	if text:match("غادر $") and is_admin(msg.sender_user_id_, msg.chat_id_) then
	     chat_leave(msg.chat_id_, bot_id)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^رفع ادمن$") and is_owner(msg.sender_user_id_, msg.chat_id_) and msg.reply_to_message_id_ then
	function promote_by_reply(extra, result, success)
	local hash = 'bot:mods:'..msg.chat_id_
	if database:sismember(hash, result.sender_user_id_) then
         send(msg.chat_id_, msg.id_, 1, '✿↲ العــــضو 【 *'..result.sender_user_id_..'*  】\n\n ✿↲   _تــــم ✔ رفعــه سابقــاًُ_🎋 '   , 1, 'md')
	else
         database:sadd(hash, result.sender_user_id_)
         send(msg.chat_id_, msg.id_, 1, '✿↲ العــــضو 【 *'..result.sender_user_id_..'*  】\n\n ✿↲   _تــــم ✔ رفعــه ادمــنُ_🎋 '  , 1, 'md')
	end
    end
	      getMessage(msg.chat_id_, msg.reply_to_message_id_,promote_by_reply)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^(رفع ادمن) @(.*)$") and is_owner(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^(رفع ادمن) @(.*)$")} 
	function promote_by_username(extra, result, success)
	if result.id_ then
	        database:sadd('bot:mods:'..msg.chat_id_, result.id_)
            texts = '✿↲ العــــضو 【 *'..result.sender_user_id_..'*  】\n\n ✿↲   _تــــم ✔ رفعــه ادمــن_🎋 ' 
            else 
            texts = '<code>🐣-العضــو غيــر موجــود⚠️❗️ </code>'
    end
	         send(msg.chat_id_, msg.id_, 1, texts, 1, 'html')
    end
	      resolve_username(ap[2],promote_by_username)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^(رفع ادمن) (%d+)$") and is_owner(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^(رفع ادمن) (%d+)$")} 	
	        database:sadd('bot:mods:'..msg.chat_id_, ap[2])
         send(msg.chat_id_, msg.id_, 1, '✿↲ العــــضو 【 *'..result.sender_user_id_..'*  】\n\n ✿↲   _تــــم ✔ رفعــه ادمــنُ_🎋 ', 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^تنزيل ادمن$") and is_owner(msg.sender_user_id_, msg.chat_id_) and msg.reply_to_message_id_ then
	function demote_by_reply(extra, result, success)
	local hash = 'bot:mods:'..msg.chat_id_
	if not database:sismember(hash, result.sender_user_id_) then
         send(msg.chat_id_, msg.id_, 1, '✿↲ العــــضو 【 *'..result.sender_user_id_..'*  】\n\n ✿↲   _تــــم ✔ تنزيله سابقاً_🎋 ', 1, 'md')
	else
         database:srem(hash, result.sender_user_id_)
         send(msg.chat_id_, msg.id_, 1, '✿↲ العــــضو 【 *'..result.sender_user_id_..'*  】\n\n ✿↲   _تــــم ✔تنزيلــه ادمــنُ_🎋 ', 1, 'md')
	end
    end
	      getMessage(msg.chat_id_, msg.reply_to_message_id_,demote_by_reply)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^(تنزيل ادمن) @(.*)$") and is_owner(msg.sender_user_id_, msg.chat_id_) then
	local hash = 'bot:mods:'..msg.chat_id_
	local ap = {string.match(text, "^(تنزيل ادمن) @(.*)$")} 
	function demote_by_username(extra, result, success)
	if result.id_ then
         database:srem(hash, result.id_)
            texts = '✿↲ العــــضو 【 *'..result.sender_user_id_..'*  】\n\n ✿↲   _تــــم ✔ تنزيله ادمــنُ_🎋 '
            else 
            texts = '<code>🐣-العضــو غيــر موجــود⚠️❗️</code>'
    end
	         send(msg.chat_id_, msg.id_, 1, texts, 1, 'html')
    end
	      resolve_username(ap[2],demote_by_username)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^(تنزيل ادمن) (%d+)$") and is_owner(msg.sender_user_id_, msg.chat_id_) then
	local hash = 'bot:mods:'..msg.chat_id_
	local ap = {string.match(text, "^(تنزيل ادمن) (%d+)$")} 	
         database:srem(hash, ap[2])
	send(msg.chat_id_, msg.id_, 1, '✿↲ العــــضو 【 *'..result.sender_user_id_..'*  】\n\n ✿↲   _تــــم ✔ تنزيله ادمــنُ_🎋 ' , 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^حظر$") and is_mod(msg.sender_user_id_, msg.chat_id_) and msg.reply_to_message_id_ then
	function ban_by_reply(extra, result, success)
	local hash = 'bot:banned:'..msg.chat_id_
	if is_mod(result.sender_user_id_, result.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '*⇦ الاّدمن او المديــر لا يمكنك حضره 😴🖕*', 1, 'md')
    else
    if database:sismember(hash, result.sender_user_id_) then
         send(msg.chat_id_, msg.id_, 1, '✿↲ العــــضو 【 *'..result.sender_user_id_..'*  】\n\n ✿↲   _تــــم ✅ حظــره _✨❗️ ' , 1, 'md')
		 chat_kick(result.chat_id_, result.sender_user_id_)
	else
         database:sadd(hash, result.sender_user_id_)
         send(msg.chat_id_, msg.id_, 1, '✿↲ العــــضو 【 *'..result.sender_user_id_..'*  】\n\n ✿↲   _تــــم ✅ حظــره _✨❗️ ', 1, 'md')
		 chat_kick(result.chat_id_, result.sender_user_id_)
	end
    end
	end
	      getMessage(msg.chat_id_, msg.reply_to_message_id_,ban_by_reply)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^(حظر) @(.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^(حظر) @(.*)$")} 
	function ban_by_username(extra, result, success)
	if result.id_ then
	if is_mod(result.id_, msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '*⇦ الاّدمن او المديــر لا يمكنك حضره 😴🖕*', 1, 'md')
    else
	        database:sadd('bot:banned:'..msg.chat_id_, result.id_)
            texts = '✿↲ العــــضو 【 *'..result.sender_user_id_..'*  】\n\n ✿↲   _تــــم ✅ حظــره _✨❗️  '
		 chat_kick(msg.chat_id_, result.id_)
	end
            else 
            texts = '<code>🐣-العضــو غيــر موجــود⚠️❗️ </code>'
    end
	         send(msg.chat_id_, msg.id_, 1, texts, 1, 'html')
    end
	      resolve_username(ap[2],ban_by_username)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^(حظر) (%d+)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^(حظر) (%d+)$")}
	if is_mod(ap[2], msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '*لا يمكنك حظر او طرد المدراء او الادمنيه 🎩!!*', 1, 'md')
    else
	        database:sadd('bot:banned:'..msg.chat_id_, ap[2])
		 chat_kick(msg.chat_id_, ap[2])
	send(msg.chat_id_, msg.id_, 1, '✿↲ العــــضو 【 *'..result.sender_user_id_..'*  】\n\n ✿↲   _تــــم ✅ حظــره _✨❗️  ', 1, 'md')
	end
    end
	-----------------------------------------------------------------------------------------------
	if text:match("مسح ") and is_owner(msg.sender_user_id_, msg.chat_id_) and msg.reply_to_message_id_ then
	function delall_by_reply(extra, result, success)
	if is_mod(result.sender_user_id_, result.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '✺-عــذراً لا يمكنــك✘ مسح رسائل الادمن او المدير 😴🖕', 1, 'md')
    else
         send(msg.chat_id_, msg.id_, 1, '✿↲ العــــضو 【 *'..result.sender_user_id_..'*  】\n\n ✿↲   _تــــم ✅ حــذف رسائــله❗️ , 1, 'md')
		     del_all_msgs(result.chat_id_, result.sender_user_id_)
    end
	end
	      getMessage(msg.chat_id_, msg.reply_to_message_id_,delall_by_reply)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("مسح (%d+)") and is_owner(msg.sender_user_id_, msg.chat_id_) then
		local ass = {string.match(text, "(مسح) (%d+)")} 
	if is_mod(ass[2], msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '✺-عــذراً لا يمكنــك✘ مسح رسائل الادمن او المدير 😴🖕', 1, 'md')
    else
	 		     del_all_msgs(msg.chat_id_, ass[2])
         send(msg.chat_id_, msg.id_, 1, '<b>✺- العظــو </b> <code>'..ass[2]..' \n\n </code> <b> ✿↲ تــم مسح ✔ رسائلــه❗️</b>', 1, 'html')
    end
	end
 -----------------------------------------------------------------------------------------------
	if text:match("مسح @(.*)") and is_owner(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "(مسح) @(.*)")} 
	function delall_by_username(extra, result, success)
	if result.id_ then
	if is_mod(result.id_, msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '✺-عــذراً لا يمكنــك✘ مسح رسائل الادمن او المدير 😴🖕 ', 1, 'md')
		 return false
    end
		 		     del_all_msgs(msg.chat_id_, result.id_)
            text = '<b>✺- العظــو </b> <code>'..result.id_..'  \n\n </code> <b> ✿↲ تــم مسح ✔ رسائلــه❗️</b>'
            else 
            text = '<code>🐣-العضــو غيــر موجــود⚠️❗️ </code>'
    end
	         send(msg.chat_id_, msg.id_, 1, text, 1, 'html')
    end
	      resolve_username(ap[2],delall_by_username)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^(الغاء حظر)$") and is_mod(msg.sender_user_id_, msg.chat_id_) and msg.reply_to_message_id_ then
	function unban_by_reply(extra, result, success)
	local hash = 'bot:banned:'..msg.chat_id_
	if not database:sismember(hash, result.sender_user_id_) then
         send(msg.chat_id_, msg.id_, 1, '✿↲ العــــضو 【 *'..result.sender_user_id_..'*  】\n\n ✿↲   _تــــم ✅ الغــاء حظره _✨❗️  ', 1, 'md')
	else
         database:srem(hash, result.sender_user_id_)
         send(msg.chat_id_, msg.id_, 1, '✿↲ العــــضو 【 *'..result.sender_user_id_..'*  】\n\n ✿↲   _تــــم ✅ الغاء حظره _✨❗️  ', 1, 'md')
	end
    end
	      getMessage(msg.chat_id_, msg.reply_to_message_id_,unban_by_reply)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^(الغاء حظر) @(.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^(الغاء حظر) @(.*)$")} 
	function unban_by_username(extra, result, success)
	if result.id_ then
         database:srem('bot:banned:'..msg.chat_id_, result.id_)
            text = '<b>✿↲ العــــضو 【   </b><code>'..result.id_..'</code> <b>】\n\n ✿↲   _تــــم ✅ الغــاء حظره _✨❗️  </b>'
            else 
            text = '<code>🐣-العضــو غيــر موجــود⚠️❗️ </code>'
    end
	         send(msg.chat_id_, msg.id_, 1, text, 1, 'html')
    end
	      resolve_username(ap[2],unban_by_username)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^(الغاء حظر) (%d+)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^(الغاء حظر) (%d+)$")} 	
	        database:srem('bot:banned:'..msg.chat_id_, ap[2])
         send(msg.chat_id_, msg.id_, 1, '⇦ الاّدمن او المديــر لا يمكنك حضره 😴🖕 ', 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^كتم") and is_mod(msg.sender_user_id_, msg.chat_id_) and msg.reply_to_message_id_ then
	function mute_by_reply(extra, result, success)
	local hash = 'bot:muted:'..msg.chat_id_
	if is_mod(result.sender_user_id_, result.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '⇦ الاّدمن او المديــر لا يمكنك كتمه 😴🖕 ', 1, 'md')
    else
    if database:sismember(hash, result.sender_user_id_) then
         send(msg.chat_id_, msg.id_, 1, '✿↲ العــــضو 【 *'..result.sender_user_id_..'*  】\n\n ✿↲   _تــــم ✅ كتمــه_✨❗️  ', 1, 'md')
	else
         database:sadd(hash, result.sender_user_id_)
         send(msg.chat_id_, msg.id_, 1, '✿↲ العــــضو 【 *'..result.sender_user_id_..'*  】\n\n ✿↲   _تــــم ✅ كتمــه_✨❗️', 1, 'md')
	end
    end
	end
	      getMessage(msg.chat_id_, msg.reply_to_message_id_,mute_by_reply)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^(كتم) @(.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^(كتم) @(.*)$")} 
	function mute_by_username(extra, result, success)
	if result.id_ then
	if is_mod(result.id_, msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '⇦ الاّدمن او المديــر لا يمكنك كتمه 😴🖕 ', 1, 'md')
    else
	        database:sadd('bot:muted:'..msg.chat_id_, result.id_)
            texts = '<b>✿↲ العــــضو 【   </b><code>'..result.id_..'</code> <b>】\n\n ✿↲   _تــــم ✅ كتمــه_✨❗️ </b>'
		 chat_kick(msg.chat_id_, result.id_)
	end
            else 
            texts = '<code>🐣-العضــو غيــر موجــود⚠️❗️ </code>'
    end
	         send(msg.chat_id_, msg.id_, 1, texts, 1, 'html')
    end
	      resolve_username(ap[2],mute_by_username)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^(كتم) (%d+)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^(حظر) (%d+)$")}
	if is_mod(ap[2], msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '⇦ الاّدمن او المديــر لا يمكنك كتمه 😴🖕  ', 1, 'md')
    else
	        database:sadd('bot:muted:'..msg.chat_id_, ap[2])
	send(msg.chat_id_, msg.id_, 1, '✿↲ العــــضو 【   *'..ap[2]..'* ✿↲ العــــضو 【 *'..result.sender_user_id_..'*  】\n\n ✿↲   _تــــم ✅ كتمــه_✨❗️ ', 1, 'md')
	end
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^الغاء الكتم") and is_mod(msg.sender_user_id_, msg.chat_id_) and msg.reply_to_message_id_ then
	function unmute_by_reply(extra, result, success)
	local hash = 'bot:muted:'..msg.chat_id_
	if not database:sismember(hash, result.sender_user_id_) then
         send(msg.chat_id_, msg.id_, 1, '✿↲ العــــضو 【 *'..result.sender_user_id_..'*  】\n\n ✿↲   _تــــم ✅ الغاء كتمه_✨❗️  ', 1, 'md')
	else
         database:srem(hash, result.sender_user_id_)
         send(msg.chat_id_, msg.id_, 1, '✿↲ العــــضو 【 *'..result.sender_user_id_..'*  】\n\n ✿↲   _تــــم ✅ الغاء كتمه_✨❗️', 1, 'md')
	end
    end
	      getMessage(msg.chat_id_, msg.reply_to_message_id_,unmute_by_reply)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^الغاء الكتم @(.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^(الغاء الكتم) @(.*)$")} 
	function unmute_by_username(extra, result, success)
	if result.id_ then
         database:srem('bot:muted:'..msg.chat_id_, result.id_)
            text = '<b>✿↲ العــــضو 【   </b><code>'..result.id_..'</code> <b>】\n\n ✿↲   _تــــم ✅ الغاء كتمه_✨❗️ </b>'
            else 
            text = '<code>🐣-العضــو غيــر موجــود⚠️❗️ </code>'
    end
	         send(msg.chat_id_, msg.id_, 1, text, 1, 'html')
    end
	      resolve_username(ap[2],unmute_by_username)
    end
    -------------------------------------------------------------------------------------------
	if text:match("^(الغاء الكتم) (%d+)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^(الغاء الكتم)) (%d+)$")} 	
	        database:srem('bot:muted:'..msg.chat_id_, ap[2])
	send(msg.chat_id_, msg.id_, 1, '✿↲ العــــضو 【   *'..ap[2]..'*】\n\n ✿↲   _تــــم ✅ الغاء كتمه_✨❗️ ', 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^(رفع مدير)$") and is_admin(msg.sender_user_id_) and msg.reply_to_message_id_ then
	function setowner_by_reply(extra, result, success)
	local hash = 'bot:owners:'..msg.chat_id_
	if database:sismember(hash, result.sender_user_id_) then
         send(msg.chat_id_, msg.id_, 1, '✿↲ العــــضو 【 *'..result.sender_user_id_..'*  】\n\n ✿↲_هــو مدير سابقآً 🎋 ', 1, 'md')
	else
         database:sadd(hash, result.sender_user_id_)
         send(msg.chat_id_, msg.id_, 1, '✿↲ العــــضو 【 *'..result.sender_user_id_..'*  】\n\n ✿↲   _تــــم ✔ رفعــه المديــر_🎋 ', 1, 'md')
	end
    end
	      getMessage(msg.chat_id_, msg.reply_to_message_id_,setowner_by_reply)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^(رفع مدير) @(.*)$") and is_admin(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^(رفع مدير) @(.*)$")} 
	function setowner_by_username(extra, result, success)
	if result.id_ then
	        database:sadd('bot:owners:'..msg.chat_id_, result.id_)
            texts = '<b>✿↲ العــــضو 【   </b><code>'..result.id_..'</code> <b>】\n\n ✿↲   _تــــم ✔ رفعــه المديــر_🎋 </b>'
            else 
            texts = '<code>🐣-العضــو غيــر موجــود⚠️❗️ </code>'
    end
	         send(msg.chat_id_, msg.id_, 1, texts, 1, 'html')
    end
	      resolve_username(ap[2],setowner_by_username)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^(رفع مدير) (%d+)$") and is_admin(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^(رفع مدير) (%d+)$")} 	
	        database:sadd('bot:owners:'..msg.chat_id_, ap[2])
	send(msg.chat_id_, msg.id_, 1, '✿↲ العــــضو 【   *'..ap[2]..'* 】\n\n ✿↲   _تــــم ✔ رفعــه المديــر_🎋 ', 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^تنزيل مدير$") and is_admin(msg.sender_user_id_) and msg.reply_to_message_id_ then
	function deowner_by_reply(extra, result, success)
	local hash = 'bot:owners:'..msg.chat_id_
	if not database:sismember(hash, result.sender_user_id_) then
         send(msg.chat_id_, msg.id_, 1, '✿↲ العــــضو 【   *'..result.sender_user_id_..'* 】\n\n ✿↲   _تــــم ✔ تنزيله المدير_🎋 ', 1, 'md')
	else
         database:srem(hash, result.sender_user_id_)
         send(msg.chat_id_, msg.id_, 1, '✿↲ العــــضو 【   *'..result.sender_user_id_..'* 】\n\n ✿↲   _تــــم ✔ تنزيله المدير_🎋 ', 1, 'md')
	end
    end
	      getMessage(msg.chat_id_, msg.reply_to_message_id_,deowner_by_reply)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^(تنزيل مدير) @(.*)$") and is_admin(msg.sender_user_id_, msg.chat_id_) then
	local hash = 'bot:owners:'..msg.chat_id_
	local ap = {string.match(text, "^(تنزيل مدير) @(.*)$")} 
	function remowner_by_username(extra, result, success)
	if result.id_ then
         database:srem(hash, result.id_)
            texts = '<b>✿↲ العــــضو 【   </b><code>'..result.id_..'</code> <b>】\n\n ✿↲   _تــــم ✔ تنزيله المدير_🎋 </b>'
            else 
            texts = '<code>🐣-العضــو غيــر موجــود⚠️❗️ </code>'
    end
	         send(msg.chat_id_, msg.id_, 1, texts, 1, 'html')
    end
	      resolve_username(ap[2],remowner_by_username)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^(تنزيل مدير) (%d+)$") and is_admin(msg.sender_user_id_, msg.chat_id_) then
	local hash = 'bot:owners:'..msg.chat_id_
	local ap = {string.match(text, "^(تنزيل مدير) (%d+)$")} 	
         database:srem(hash, ap[2])
	send(msg.chat_id_, msg.id_, 1, '✿↲ العــــضو 【   *'..ap[2]..'* 】\n\n ✿↲   _تــــم ✔ تنزيله المدير_🎋 ', 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^الادمنيه") and is_mod(msg.sender_user_id_, msg.chat_id_) then
    local hash =  'bot:mods:'..msg.chat_id_
	local list = database:smembers(hash)
	local text = "</b>✧قائمــه الادمنــة✧</b>\nٱ┏━━━━━┓ٱ\n"
	for k,v in pairs(list) do
	local user_info = database:hgetall('العضو:'..v)
		if user_info and user_info.username then
			local username = user_info.username
			text = text..k.." - @"..username.." ["..v.."]\n"
		else
			text = text..k.." - "..v.."\n"
		end
	end
	if #list == 0 then
       text = "◯↲لا يوجــــد ادمنــيه❗️"
    end
	send(msg.chat_id_, msg.id_, 1, text, 1, 'html')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^المكتومين") and is_mod(msg.sender_user_id_, msg.chat_id_) then
    local hash =  'bot:muted:'..msg.chat_id_
	local list = database:smembers(hash)
	local text = "<b>✯قائمــة المكتوميــن✯</b>\nٱ✞━━━━━━✞ٱ\n"
	for k,v in pairs(list) do
	local user_info = database:hgetall('user:'..v)
		if user_info and user_info.username then
			local username = user_info.username
			text = text..k.." - @"..username.." ["..v.."]\n"
		else
			text = text..k.." - "..v.."\n"
		end
	end
	if #list == 0 then
       text = "◯↲لا يوجــد مكتومــين❗️"
    end
	send(msg.chat_id_, msg.id_, 1, text, 1, 'html')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^المدير$") or text:match("^المدراء$") and is_sudo(msg) then
    local hash =  'bot:owners:'..msg.chat_id_
	local list = database:smembers(hash)
	local text = "<b>🇲🇦مدراء المجموعــه الصاكين:⇩</b>\n\n"
	for k,v in pairs(list) do
	local user_info = database:hgetall('user:'..v)
		if user_info and user_info.username then
			local username = user_info.username
			text = text..k.." - @"..username.." ["..v.."]\n"
		else
			text = text..k.." - "..v.."\n"
		end
	end
	if #list == 0 then
       text = "◯↲لا يوجد مديــر❗️"
    end
	send(msg.chat_id_, msg.id_, 1, text, 1, 'html')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^المحظورين$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
    local hash =  'bot:banned:'..msg.chat_id_
	local list = database:smembers(hash)
	local text = "<b>⚜️قائمــة المحظورين :⇩</b>\nٱ┏━━━━━┓ٱ\n"
	for k,v in pairs(list) do
	local user_info = database:hgetall('user:'..v)
		if user_info and user_info.username then
			local username = user_info.username
			text = text..k.." - @"..username.." ["..v.."]\n"
		else
			text = text..k.." - "..v.."\n"
		end
	end
	if #list == 0 then
       text = "◯↲ لا يوجد محظورين❗️"
    end
	send(msg.chat_id_, msg.id_, 1, text, 1, 'html')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^الادمنيه") and is_sudo(msg) then
    local hash =  'bot:admins:'
	local list = database:smembers(hash)
	local text = "☆الادمنيه :⇩ : \nٱ┏━━━━┓ٱ\n"
	for k,v in pairs(list) do
	local user_info = database:hgetall('user:'..v)
		if user_info and user_info.username then
			local username = user_info.username
			text = text..k.." - @"..username.." ["..v.."]\n"
		else
			text = text..k.." - "..v.."\n"
		end
	end
	if #list == 0 then
       text = "_◯↲لا يوجد ادمنيــه❗️_"
    end
    send(msg.chat_id_, msg.id_, 1, '`'..text..'`', 'md')
    end
	-----------------------------------------------------------------------------------------------
    if text:match("^ايدي$") and msg.reply_to_message_id_ ~= 0 then
      function id_by_reply(extra, result, success)
	  local user_msgs = database:get('user:msgs'..result.chat_id_..':'..result.sender_user_id_)
        send(msg.chat_id_, msg.id_, 1, "*✥- ﺈيــديك :: ❰ * "..result.sender_user_id_.." ❱ ", 1, 'md')
        end
   getMessage(msg.chat_id_, msg.reply_to_message_id_,id_by_reply)
  end
  -----------------------------------------------------------------------------------------------
    if text:match("^(ايدي) @(.*)$") then
	local ap = {string.match(text, "^(ايدي) @(.*)$")} 
	function id_by_username(extra, result, success)
	if result.id_ then
	if is_sudo(result) then
	t = '*مــطور♩ *'
      elseif is_admin(msg.sender_user_id_) then
	  t = '*ادمــِّن 🐯*'
      elseif is_owner(msg.sender_user_id_, msg.chat_id_) then
	  t = '*مــدير🦁*'
      elseif is_mod(msg.sender_user_id_, msg.chat_id_) then
	  t = '*عــضو 🐒*'
      else
	  t = '*عــضو 🐒*'
	  end
            texts = '*◾️⇩المعــرف* : `@'..ap[2]..'`\n\n*◾️⇩ الايــدي * : `('..result.id_..')`\n\n*◾️⇩ الرتبــه * : `'..t..'`'
            else 
            texts = '<code>🐣-العضــو غيــر موجــود⚠️❗️ </code>'
    end
	         send(msg.chat_id_, msg.id_, 1, texts, 1, 'md')
    end
	      resolve_username(ap[2],id_by_username)
    end
    -----------------------------------------------------------------------------------------------
  if text:match("^طرد$") and msg.reply_to_message_id_ and is_mod(msg.sender_user_id_, msg.chat_id_) then
      function kick_reply(extra, result, success)
	if is_mod(result.sender_user_id_, result.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '*⇦ الاّدمن او المديــر لا يمكنك طرده 😴🖕  *', 1, 'md')
    else
        send(msg.chat_id_, msg.id_, 1, '✿↲ العــــضو 【 *'..result.sender_user_id_..'*  】\n\n ✿↲   _تــــم ✅ طرده_✨❗️ ', 1, 'html')
        chat_kick(result.chat_id_, result.sender_user_id_)
        end
	end
   getMessage(msg.chat_id_,msg.reply_to_message_id_,kick_reply)
    end
    -----------------------------------------------------------------------------------------------
  if text:match("^اضافه") and msg.reply_to_message_id_ and is_sudo(msg) then
      function inv_reply(extra, result, success)
           add_user(result.chat_id_, result.sender_user_id_, 5)
        end
   getMessage(msg.chat_id_, msg.reply_to_message_id_,inv_reply)
    end
	-----------------------------------------------------------------------------------------------
	local text = msg.content_.text_:gsub( 'صوره' )
    if text:match("^getpro  (%d+)$") and msg.reply_to_message_id_ == 0  then
		local pronumb = {string.match(text, "^(getpro) (%d+)$")} 
local function gpro(extra, result, success)
--vardump(result)
   if pronumb[2] == '1' then
   if result.photos_[0] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[0].sizes_[1].photo_.persistent_id_)
   else
      send(msg.chat_id_, msg.id_, 1, "📮-لا توجد صوره في الحساب🎈", 1, 'md')
   end
   elseif pronumb[2] == '2' then
   if result.photos_[1] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[1].sizes_[1].photo_.persistent_id_)
   else
      send(msg.chat_id_, msg.id_, 1, "📮-لا توجد صوره 2 في الحساب🎌", 1, 'md')
   end
   elseif pronumb[2] == '3' then
   if result.photos_[2] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[2].sizes_[1].photo_.persistent_id_)
   else
      send(msg.chat_id_, msg.id_, 1, "📮- لا توجــد صوره 3 في الحساب🎐", 1, 'md')
   end
   elseif pronumb[2] == '4' then
      if result.photos_[3] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[3].sizes_[1].photo_.persistent_id_)
   else
      send(msg.chat_id_, msg.id_, 1, "📮- لا توجــد صوره 4 في الحساب🎐", 1, 'md')
   end
   elseif pronumb[2] == '5' then
   if result.photos_[4] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[4].sizes_[1].photo_.persistent_id_)
   else
      send(msg.chat_id_, msg.id_, 1, "📮- لا توجــد صوره 5 في الحساب🎐", 1, 'md')
   end
   elseif pronumb[2] == '6' then
   if result.photos_[5] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[5].sizes_[1].photo_.persistent_id_)
   else
      send(msg.chat_id_, msg.id_, 1, "📮- لا توجــد صوره 6 في الحساب🎐", 1, 'md')
   end
   elseif pronumb[2] == '7' then
   if result.photos_[6] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[6].sizes_[1].photo_.persistent_id_)
   else
      send(msg.chat_id_, msg.id_, 1, "📮- لا توجــد صوره 7 في الحساب🎐", 1, 'md')
   end
   elseif pronumb[2] == '8' then
   if result.photos_[7] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[7].sizes_[1].photo_.persistent_id_)
   else
      send(msg.chat_id_, msg.id_, 1, "📮- لا توجــد صوره 8 في الحساب🎐", 1, 'md')
   end
   elseif pronumb[2] == '9' then
   if result.photos_[8] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[8].sizes_[1].photo_.persistent_id_)
   else
      send(msg.chat_id_, msg.id_, 1, "📮- لا توجــد صوره 9 في الحساب🎐", 1, 'md')
   end
   elseif pronumb[2] == '10' then
   if result.photos_[9] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[9].sizes_[1].photo_.persistent_id_)
   else
      send(msg.chat_id_, msg.id_, 1, "📮- لا توجــد صوره 10 في الحساب🎐", 1, 'md')
   end
   else
      send(msg.chat_id_, msg.id_, 1, "*🚸-يمكنك جلب الى الصوره 10 فقط❗️*", 1, 'md')
   end
   end
   tdcli_function ({
    ID = "GetUserProfilePhotos",
    user_id_ = msg.sender_user_id_,
    offset_ = 0,
    limit_ = pronumb[2]
  }, gpro, nil)
	end
	-----------------------------------------------------------------------------------------------
	if text:match("^(قفل) (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local lockpt = {string.match(text, "^(قفل) (.*)$")} 
      if lockpt[2] == "التعديل" then
         send(msg.chat_id_, msg.id_, 1, '🎆 ⏎  ﺂلايــدي【*'..result.sender_user_id_..'* 】\n\n 🎆 ⏎  تــم ✔ قفــل التعديــل🔏❗️ ', 1, 'md')
         database:set('editmsg'..msg.chat_id_,'delmsg')
	  end
	  if lockpt[2] == "الاوامر" then
         send(msg.chat_id_, msg.id_, 1, '🎆 ⏎  ﺂلآيــدي【*'..result.sender_user_id_..'* 】\n\n 🎆 ⏎  تــم ✔ قفــل الاوامــر🔏❗️', 1, 'md')
         database:set('bot:cmds'..msg.chat_id_,true)
      end
	  if lockpt[2] == "البوتات" then
         send(msg.chat_id_, msg.id_, 1, '🎆 ⏎  ﺂلايــدي【*'..result.sender_user_id_..'* 】\n\n 🎆 ⏎  تــم ✔ قفــل البوتات🔏❗️', 1 , 'md')
         database:set('bot:bots:mute'..msg.chat_id_,true)
      end
	  if lockpt[2] == "التكرار" then
         send(msg.chat_id_, msg.id_, 1, '🎆 ⏎  ﺂلايــدي【*'..result.sender_user_id_..'* 】\n\n 🎆 ⏎  تــم ✔ قفــل التكــرار🔏❗️', 1, 'md')
         database:del('anti-flood:'..msg.chat_id_)
	  end
	  if lockpt[2] == "التثبيت" then
         send(msg.chat_id_, msg.id_, 1, '🎆 ⏎  ﺂلايــدي【*'..result.sender_user_id_..'* 】\n\n 🎆 ⏎  تــم ✔ قفــل التــثبيت🔏❗️ ', 1, 'md')
	     database:set('bot:pin:mute'..msg.chat_id_,true)
      end
	end
	-----------------------------------------------------------------------------------------------
  	if text:match("^(فتح) (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local unlockpt = {string.match(text, "^(فتح) (.*)$")} 
      if unlockpt[2] == "التعديل" then
         send(msg.chat_id_, msg.id_, 1, '🎆 ⏎  ﺂلايــدي【*'..result.sender_user_id_..'* 】\n\n 🎆 ⏎  تــم ✔ فتــح التعديــل🔓❗️ ', 1, 'md')

         database:del('editmsg'..msg.chat_id_)
      end
	  if unlockpt[2] == "الاوامر" then
         send(msg.chat_id_, msg.id_, 1, '🎆 ⏎  ﺂلايــدي【*'..result.sender_user_id_..'* 】\n\n 🎆 ⏎  تــم ✔ فتــح الآوامــر🔓❗️', 1, 'md')
         database:del('bot:cmds'..msg.chat_id_)
      end
	  if unlockpt[2] == "البوتات" then
         send(msg.chat_id_, msg.id_, 1, '🎆 ⏎  ﺂلايــدي【*'..result.sender_user_id_..'* 】\n\n 🎆 ⏎  تــم ✔ فتــح البوتــات🔓❗️', 1, 'md')
         database:del('bot:bots:mute'..msg.chat_id_)
      end
	  if unlockpt[2] == "التكرار" then
         send(msg.chat_id_, msg.id_, 1, '🎆 ⏎  ﺂلايــدي【*'..result.sender_user_id_..'* 】\n\n 🎆 ⏎  تــم ✔ فتــح التــكرار🔓❗️', 1, 'md')
         database:set('anti-flood:'..msg.chat_id_,true)
	  end
	  if unlockpt[2] == "التثبيت" then
         send(msg.chat_id_, msg.id_, 1, '🎆 ⏎  ﺂلايــدي【*'..result.sender_user_id_..'* 】\n\n 🎆 ⏎  تــم ✔ فتــح التــثبيت🔓❗️ ', 1, 'md')
	     database:del('bot:pin:mute'..msg.chat_id_)
      end
    end
	-----------------------------------------------------------------------------------------------
  if text:match("^(قفل) (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local mutept = {string.match(text, "^(قفل) (.*)$")} 
     
	  if mutept[2] == "الدردشه" then
         send(msg.chat_id_, msg.id_, 1, '🎆 ⏎  ﺂلايــدي【*'..result.sender_user_id_..'* 】\n\n 🎆 ⏎  تــم ✔ قفــل الدردشــه🔏❗️ ', 1, 'md')
         database:set('bot:text:mute'..msg.chat_id_,true)
      end
	  if mutept[2] == "الانلاين" then
         send(msg.chat_id_, msg.id_, 1, '🎆 ⏎  ﺂلايــدي【*'..result.sender_user_id_..'* 】\n\n 🎆 ⏎  تــم ✔ قفــل الانلايــن🔏❗️ ', 1, 'md')
         database:set('bot:inline:mute'..msg.chat_id_,true)
      end
	  if mutept[2] == "الصور" then
         send(msg.chat_id_, msg.id_, 1, '🎆 ⏎  ﺂلايــدي【*'..result.sender_user_id_..'* 】\n\n 🎆 ⏎  تــم ✔ قفــل الصــور🔏❗️ ', 1, 'md')
         database:set('bot:photo:mute'..msg.chat_id_,true)
      end
	  if mutept[2] == "الفيديو" then
         send(msg.chat_id_, msg.id_, 1, '🎆 ⏎  ﺂلايــدي【*'..result.sender_user_id_..'* 】\n\n 🎆 ⏎  تــم ✔ قفــل الفيديــو🔏❗️', 1, 'md')
         database:set('bot:video:mute'..msg.chat_id_,true)
      end
	  if mutept[2] == "المتحركه" then
         send(msg.chat_id_, msg.id_, 1, '🎆 ⏎  ﺂلايــدي【*'..result.sender_user_id_..'* 】\n\n 🎆 ⏎  تــم ✔ قفــل المتحركــه🔏❗️', 1, 'md')
         database:set('bot:gifs:mute'..msg.chat_id_,true)
      end
	  if mutept[2] == "الاغاني" then
         send(msg.chat_id_, msg.id_, 1, '🎆 ⏎  ﺂلايــدي【*'..result.sender_user_id_..'* 】\n\n 🎆 ⏎  تــم ✔ قفــل الاغانــي🔏❗️', 1, 'md')
         database:set('bot:music:mute'..msg.chat_id_,true)
      end
	  if mutept[2] == "الصوت" then
         send(msg.chat_id_, msg.id_, 1, '🎆 ⏎  ﺂلايــدي【*'..result.sender_user_id_..'* 】\n\n 🎆 ⏎  تــم ✔ قفــل الصـــوت🔏❗️', 1, 'md')
         database:set('bot:voice:mute'..msg.chat_id_,true)
      end
	  if mutept[2] == "الروابط" then
         send(msg.chat_id_, msg.id_, 1, '🎆 ⏎  ﺂلايــدي【*'..result.sender_user_id_..'* 】\n\n 🎆 ⏎  تــم ✔ قفــل الروابــط🔏❗️', 1, 'md')
         database:set('bot:links:mute'..msg.chat_id_,true)
      end
	  if mutept[2] == "المواقع" then
         send(msg.chat_id_, msg.id_, 1, '🎆 ⏎  ﺂلايــدي【*'..result.sender_user_id_..'* 】\n\n 🎆 ⏎  تــم ✔ قفــل المواقــع🔏❗️', 1, 'md')
         database:set('bot:location:mute'..msg.chat_id_,true)
      end
	  if mutept[2] == "المعرف" then
         send(msg.chat_id_, msg.id_, 1, '🎆 ⏎  ﺂلايــدي【*'..result.sender_user_id_..'* 】\n\n 🎆 ⏎  تــم ✔ قفــل المعرفــات🔏❗️', 1, 'md')
         database:set('bot:tag:mute'..msg.chat_id_,true)
      end
	  if mutept[2] == "الجهات" then
         send(msg.chat_id_, msg.id_, 1, '🎆 ⏎  ﺂلايــدي【*'..result.sender_user_id_..'* 】\n\n 🎆 ⏎  تــم ✔ قفــل الجهــات🔏❗️', 1, 'md')
         database:set('bot:contact:mute'..msg.chat_id_,true)
      end
	  if mutept[2] == "#" then
         send(msg.chat_id_, msg.id_, 1, '🎆 ⏎  ﺂلايــدي【*'..result.sender_user_id_..'* 】\n\n 🎆 ⏎  تــم ✔ قفــل (#)🔏❗️', 1, 'md')
         database:set('bot:webpage:mute'..msg.chat_id_,true)
      end
	  if mutept[2] == "العربية" then
         send(msg.chat_id_, msg.id_, 1, '🎆 ⏎  ﺂلايــدي【*'..result.sender_user_id_..'* 】\n\n 🎆 ⏎  تــم ✔ قفــل العربيــة🔏❗️', 1, 'md')
         database:set('bot:arabic:mute'..msg.chat_id_,true)
      end
	  if mutept[2] == "الانكليزية" then
         send(msg.chat_id_, msg.id_, 1, '🎆 ⏎  ﺂلايــدي【*'..result.sender_user_id_..'* 】\n\n 🎆 ⏎  تــم ✔ قفــل الانكليزيــة🔏❗️', 1, 'md')
         database:set('bot:english:mute'..msg.chat_id_,true)
      end 
	  if mutept[2] == "الملصقات" then
         send(msg.chat_id_, msg.id_, 1, '🎆 ⏎  ﺂلايــدي【*'..result.sender_user_id_..'* 】\n\n 🎆 ⏎  تــم ✔ قفــل الملصقــات🔏❗️', 1, 'md')
         database:set('bot:sticker:mute'..msg.chat_id_,true)
      end 
	  if mutept[2] == "التوجيه" then
         send(msg.chat_id_, msg.id_, 1, '🎆 ⏎  ﺂلايــدي【*'..result.sender_user_id_..'* 】\n\n 🎆 ⏎  تــم ✔ قفــل التوجيــه🔏❗️', 1, 'md')
         database:set('bot:forward:mute'..msg.chat_id_,true)
      end
	end
	-----------------------------------------------------------------------------------------------
  	if text:match("^(فتح) (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local unmutept = {string.match(text, "^(فتح) (.*)$")} 
      if unmutept[2] == "الدردشه" then
         send(msg.chat_id_, msg.id_, 1, '🎆 ⏎  ﺂلايــدي【*'..result.sender_user_id_..'* 】\n\n 🎆 ⏎  تــم ✔ فتــح الدردشــه🔓❗️ ', 1, 'md')
         database:del('bot:text:mute'..msg.chat_id_)
      end
	  if unmutept[2] == "الصور" then
         send(msg.chat_id_, msg.id_, 1, '🎆 ⏎  ﺂلايــدي【*'..result.sender_user_id_..'* 】\n\n 🎆 ⏎  تــم ✔ فتــح الــصور🔓❗️ ', 1, 'md')
         database:del('bot:photo:mute'..msg.chat_id_)
      end
	  if unmutept[2] == "الفيديو" then
         send(msg.chat_id_, msg.id_, 1, '🎆 ⏎  ﺂلايــدي【*'..result.sender_user_id_..'* 】\n\n 🎆 ⏎  تــم ✔ فتــح الفيديو🔓❗️', 1, 'md')
         database:del('bot:video:mute'..msg.chat_id_)
      end
	  if unmutept[2] == "الانلاين" then
         send(msg.chat_id_, msg.id_, 1, '🎆 ⏎  ﺂلايــدي【*'..result.sender_user_id_..'* 】\n\n 🎆 ⏎  تــم ✔ فتــح الانلايــن🔓❗️', 1, 'md')
         database:del('bot:inline:mute'..msg.chat_id_)
      end
	  if unmutept[2] == "المتحركه" then
         send(msg.chat_id_, msg.id_, 1, '🎆 ⏎  ﺂلايــدي【*'..result.sender_user_id_..'* 】\n\n 🎆 ⏎  تــم ✔ فتــح الـمتحركــه🔓❗️', 1, 'md')
         database:del('bot:gifs:mute'..msg.chat_id_)
      end
	  if unmutept[2] == "الاغاني" then
         send(msg.chat_id_, msg.id_, 1, '🎆 ⏎  ﺂلايــدي【*'..result.sender_user_id_..'* 】\n\n 🎆 ⏎  تــم ✔ فتــح الاغانــي🔓❗️', 1, 'md')
         database:del('bot:music:mute'..msg.chat_id_)
      end
	  if unmutept[2] == "الصوت" then
         send(msg.chat_id_, msg.id_, 1, '🎆 ⏎  ﺂلايــدي【*'..result.sender_user_id_..'* 】\n\n 🎆 ⏎  تــم ✔ فتــح الـصــوت🔓❗️', 1, 'md')
         database:del('bot:voice:mute'..msg.chat_id_)
      end
	  if unmutept[2] == "الروابط" then
         send(msg.chat_id_, msg.id_, 1, '🎆 ⏎  ﺂلايــدي【*'..result.sender_user_id_..'* 】\n\n 🎆 ⏎  تــم ✔ فتــح الـروابــط🔓❗️', 1, 'md')
         database:del('bot:links:mute'..msg.chat_id_)
      end
	  if unmutept[2] == "المواقع" then
         send(msg.chat_id_, msg.id_, 1, '🎆 ⏎  ﺂلايــدي【*'..result.sender_user_id_..'* 】\n\n 🎆 ⏎  تــم ✔ فتــح الــمواقع🔓❗️', 1, 'md')
         database:del('bot:location:mute'..msg.chat_id_)
      end
	  if unmutept[2] == "المعرف" then
         send(msg.chat_id_, msg.id_, 1, '🎆 ⏎  ﺂلايــدي【*'..result.sender_user_id_..'* 】\n\n 🎆 ⏎  تــم ✔ فتــح الــمعرف🔓❗️', 1, 'md')
         database:del('bot:tag:mute'..msg.chat_id_)
      end
	  if unmutept[2] == "#" then
         send(msg.chat_id_, msg.id_, 1, '🎆 ⏎  ﺂلايــدي【*'..result.sender_user_id_..'* 】\n\n 🎆 ⏎  تــم ✔ فتــح (#)🔓❗️', 1, 'md')
         database:del('bot:hashtag:mute'..msg.chat_id_)
      end
	  if unmutept[2] == "الجهات" then
         send(msg.chat_id_, msg.id_, 1, '🎆 ⏎  ﺂلايــدي【*'..result.sender_user_id_..'* 】\n\n 🎆 ⏎  تــم ✔ فتــح الــجهات🔓❗️', 1, 'md')
         database:del('bot:contact:mute'..msg.chat_id_)
      end
	  if unmutept[2] == "العربية" then
         send(msg.chat_id_, msg.id_, 1, '🎆 ⏎  ﺂلايــدي【*'..result.sender_user_id_..'* 】\n\n 🎆 ⏎  تــم ✔ فتــح الـعربيــة🔓❗️', 1, 'md')
         database:del('bot:arabic:mute'..msg.chat_id_)
      end
	  if unmutept[2] == "الانكليزية" then
         send(msg.chat_id_, msg.id_, 1, '🎆 ⏎  ﺂلايــدي【*'..result.sender_user_id_..'* 】\n\n 🎆 ⏎  تــم ✔ فتــح الانكليزيــه🔓❗️', 1, 'md')
         database:del('bot:english:mute'..msg.chat_id_)
      end
	  if unmutept[2] == "الملصقات" then
         send(msg.chat_id_, msg.id_, 1, '🎆 ⏎  ﺂلايــدي【*'..result.sender_user_id_..'* 】\n\n 🎆 ⏎  تــم ✔ فتــح الـملصقات🔓❗️', 1, 'md')
         database:del('bot:sticker:mute'..msg.chat_id_)
      end
	  if unmutept[2] == "التوجيه" then
         send(msg.chat_id_, msg.id_, 1, '🎆 ⏎  ﺂلايــدي【*'..result.sender_user_id_..'* 】\n\n 🎆 ⏎  تــم ✔ فتــح الــتوجيه🔓❗️', 1, 'md')
         database:del('bot:forward:mute'..msg.chat_id_)
      end 
	end
	-----------------------------------------------------------------------------------------------
  	if text:match("^(التعديل) (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local editmsg = {string.match(text, "^(التعديل) (.*)$")} 
		 edit(msg.chat_id_, msg.reply_to_message_id_, nil, editmsg[2], 1, 'html')
    end
	-----------------------------------------------------------------------------------------------
  	if text:match("^المعرف$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	          send(msg.chat_id_, msg.id_, 1, '*'..from_username(msg)..'*', 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
  	if text:match("^(مسح) (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local txt = {string.match(text, "^(مسح) (.*)$")} 
       if txt[2] == 'banlist' then
	      database:del('bot:banned:'..msg.chat_id_)
	          send(msg.chat_id_, msg.id_, 1, '▪️- تــم مســح الــبوتات✞❗️' , 1, 'md')
       end
	   if txt[2] == 'البوتات' then
	  local function g_bots(extra,result,success)
      local bots = result.members_
      for i=0 , #bots do
          chat_kick(msg.chat_id_,bots[i].user_id_)
          end
      end
    channel_get_bots(msg.chat_id_,g_bots)
	          send(msg.chat_id_, msg.id_, 1, '▪️- تــم مســح الــبوتات✞❗️', 1, 'md')
	end
	   if txt[2] == 'الادمنيه' then
	      database:del('bot:mods:'..msg.chat_id_)
          send(msg.chat_id_, msg.id_, 1, '▫️- *تــم مسح قائمــه الادمنيه♩*', 1, 'md')
       end
	   if txt[2] == 'قائمه المنع' then
	      database:del('bot:filters:'..msg.chat_id_)
          send(msg.chat_id_, msg.id_, 1, '♦️￤ *تــم مسح قائمه المنع*❗️', 1, 'md')
       end
	   if txt[2] == 'المكتومين' then
	      database:del('bot:muted:'..msg.chat_id_)
          send(msg.chat_id_, msg.id_, 1, '♦️￤* تــم مسح المكتوميــن🏴*', 1, 'md')
       end
    end
	-----------------------------------------------------------------------------------------------
  	 if text:match("^الاعدادات$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	if database:get('bot:muteall'..msg.chat_id_) then
	mute_all = '`[مفعل | 🔐]`'
	else
	mute_all = '`[معطل | 🔓]`'
	end
	------------
	if database:get('bot:text:mute'..msg.chat_id_) then
	mute_text = '`[مفعل | 🔐]`'
	else
	mute_text = '`[معطل | 🔓]`'
	end
	------------
	if database:get('bot:photo:mute'..msg.chat_id_) then
	mute_photo = '`[مفعل | 🔐]`'
	else
	mute_photo = '`[معطل | 🔓]`'
	end
	------------
	if database:get('bot:video:mute'..msg.chat_id_) then
	mute_video = '`[مفعل | 🔐]`'
	else
	mute_video = '`[معطل | 🔓]`'
	end
	------------
	if database:get('bot:gifs:mute'..msg.chat_id_) then
	mute_gifs = '`[مفعل | 🔐]`'
	else
	mute_gifs = '`[معطل | 🔓]`'
	end
	------------
	if database:get('anti-flood:'..msg.chat_id_) then
	mute_flood = '`[مفعل | 🔓]`'
	else
	mute_flood = '`[معطل | 🔐]`'
	end
	------------
	if not database:get('flood:max:'..msg.chat_id_) then
	flood_m = 5
	else
	flood_m = database:get('flood:max:'..msg.chat_id_)
	end
	------------
	if not database:get('flood:time:'..msg.chat_id_) then
	flood_t = 3
	else
	flood_t = database:get('flood:time:'..msg.chat_id_)
	end
	------------
	if database:get('bot:music:mute'..msg.chat_id_) then
	mute_music = '`[مفعل | 🔐]`'
	else
	mute_music = '`[معطل | 🔓]`'
	end
	------------
	if database:get('bot:bots:mute'..msg.chat_id_) then
	mute_bots = '`[مفعل | 🔐]`'
	else
	mute_bots = '`[معطل | 🔓]`'
	end
	------------
	if database:get('bot:inline:mute'..msg.chat_id_) then
	mute_in = '`[مفعل | 🔐]`'
	else
	mute_in = '`[معطل | 🔓]`'
	end
	------------
	if database:get('bot:cmds'..msg.chat_id_) then
	mute_cmd = '[مفعل|🔐]'
	else
	mute_cmd = '[معطل|🔓]'
	end
	------------
	if database:get('bot:voice:mute'..msg.chat_id_) then
	mute_voice = '`[مفعل | 🔐]`'
	else
	mute_voice = '`[معطل | 🔓]`'
	end
	------------
	if database:get('editmsg'..msg.chat_id_) then
	mute_edit = '`[مفعل | 🔐]`'
	else
	mute_edit = '`[معطل | 🔓]`'
	end
    ------------
	if database:get('bot:links:mute'..msg.chat_id_) then
	mute_links = '`[مفعل | 🔐]`'
	else
	mute_links = '`[معطل | 🔓]`'
	end
    ------------
	if database:get('bot:pin:mute'..msg.chat_id_) then
	lock_pin = '`[مفعل | 🔐]`'
	else
	lock_pin = '`[معطل | 🔓]`'
	end 
    ------------
	if database:get('bot:sticker:mute'..msg.chat_id_) then
	lock_sticker = '`[مفعل | 🔐]`'
	else
	lock_sticker = '`[معطل | 🔓]`'
	end
	------------
    if database:get('bot:tgservice:mute'..msg.chat_id_) then
	lock_tgservice = '`[مفعل | 🔐]`'
	else
	lock_tgservice = '`[معطل | 🔓]`'
	end
	------------
    if database:get('bot:webpage:mute'..msg.chat_id_) then
	lock_wp = '`[مفعل | 🔐]`'
	else
	lock_wp = '`[معطل | 🔓]`'
	end
	------------
    if database:get('bot:hashtag:mute'..msg.chat_id_) then
	lock_htag = '`[مفعل | 🔐]`'
	else
	lock_htag = '`[معطل | 🔓]`'
	end
	------------
    if database:get('bot:tag:mute'..msg.chat_id_) then
	lock_tag = '`[مفعل | 🔐]`'
	else
	lock_tag = '`[معطل | 🔓]`'
	end
	------------
    if database:get('bot:location:mute'..msg.chat_id_) then
	lock_location = '`[مفعل | 🔐]`'
	else
	lock_location = '`[معطل | 🔓]`'
	end
	------------
    if database:get('bot:contact:mute'..msg.chat_id_) then
	lock_contact = '`[مفعل | 🔐]`'
	else
	lock_contact = '`[معطل | 🔓]`'
	end
	------------
    if database:get('bot:english:mute'..msg.chat_id_) then
	lock_english = '`[مفعل | 🔐]`'
	else
	lock_english = '`[معطل | 🔓]`'
	end
	------------
    if database:get('bot:arabic:mute'..msg.chat_id_) then
	lock_arabic = '`[مفعل | 🔐]`'
	else
	lock_arabic = '`[معطل | 🔓]`'
	end
	------------
    if database:get('bot:forward:mute'..msg.chat_id_) then
	lock_forward = '`[مفعل | 🔐]`'
	else
	lock_forward = '`[معطل | 🔓]`'
	end
	------------
	if database:get("bot:welcome"..msg.chat_id_) then
	send_welcome = '[مفعل|🔐]'
	else
	send_welcome = '[معطل |🔓]'
	end
	------------
	local ex = database:ttl("bot:charge:"..msg.chat_id_)
                if ex == -1 then
				exp_dat = 'مفعله'
				else
				exp_dat = math.floor(ex / 86400) + 1
			    end
 	------------
 local TXT = " ⚜اعدادات المجموعـه⚜:⇩ \n ٴ✞━━━━━━━━✞ \n💠↲  قفل الــــصور : "..mute_photo.." \n\n💠↲ قفل التـوجيــه :  "..lock_forward.."  \n\n💠↲ قفل الصــــوت : "..mute_voice.."  \n\n💠↲ قفل الملصقات : "..mute_sticker.." \n\n💠↲ قفل الـــفيديو : "..mute_video.." \n\n💠↲ قفل الـــروابط : "..lock_links.." \n\n💠↲ قفل التـعديــل : "..mute_edit.."  \n\n💠↲ قفل الـــــتكرار : "..mute_flood.."  \n\n💠↲ قفل الـتثبيـت : "..lock_pin.."  \n\n💠↲ قفل البوتـــات : "..mute_bots.."  \n\n💠↲ قفل الانـــلاين : "..mute_in.."  \n\n💠↲ قفل التـــــــاك : "..lock_htag.."  \n " 
         send(msg.chat_id_, msg.id_, 1, TXT, 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
  	if text:match("كول (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local txt = {string.match(text, "(كول) (.*)$")} 
         send(msg.chat_id_, msg.id_, 1, txt[2], 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[Ss][Ee][Tt][Ll][Ii][Nn][Kk]$") and is_mod(msg.sender_user_id_, msg.chat_id_) or text:match("^ضع رابط$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
         database:set("bot:group:link"..msg.chat_id_, 'Waiting For Link!\nPls Send Group Link')
                if database:get('lang:gp:'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '*◯↲ قم بآرسال الرابط الخــاص♬♩*', 1, 'md')
else 
         send(msg.chat_id_, msg.id_, 1, '*◯↲ قم بآرسال الرابط الخــاص♬♩*', 1, 'md')
end
  end
  —---------------------------------------------------------------------------------------------
  if text:match("^[Ll][Ii][Nn][Kk]$") or text:match("^الرابط$") then
  local link = database:get("bot:group:link"..msg.chat_id_)
    if link then
                if database:get('lang:gp:'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '<b>Group link:</b>\n'..link, 1, 'html')
       else 
                  send(msg.chat_id_, msg.id_, 1, '• <code>رابط المجموعــــه ⇩ :</code>\n'..link, 1, 'html')
end
    else
                if database:get('lang:gp:'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '*There is not link set yet. Please add one by #setlink .*', 1, 'md')
       else 
                  send(msg.chat_id_, msg.id_, 1, '◯↲خطآ لم يتم حفظ الرابط\n قم بارسال 【ضع رابط】 ', 1, 'md')
end
    end
   end
  
  if text:match("^[Ww][Ll][Cc] [Oo][Nn]$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '#Done\nWelcome *Enabled* In This Supergroup.', 1, 'md')
     database:set("bot:welcome"..msg.chat_id_,true)
  end
  if text:match("^[Ww][Ll][Cc] [Oo][Ff][Ff]$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '#Done\nWelcome *Disabled* In This Supergroup.', 1, 'md')
     database:del("bot:welcome"..msg.chat_id_)
  end
  
  if text:match("^تفعيل الترحيب$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '❂⏎ تم تفعيل الترحيب🎌', 1, 'md')
     database:set("bot:welcome"..msg.chat_id_,true)
  end
  if text:match("^تعطيل الترحيب$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '❂⏎ تــم تعطيــل الترحيب❗️', 1, 'md')
     database:del("bot:welcome"..msg.chat_id_)
  end

  if text:match("^[Ss][Ee][Tt] [Ww][Ll][Cc] (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
  local welcome = {string.match(text, "^([Ss][Ee][Tt] [Ww][Ll][Cc]) (.*)$")} 
         send(msg.chat_id_, msg.id_, 1, '*Welcome Msg Has Been Saved!*\nWlc Text:\n\n`'..welcome[2]..'`', 1, 'md')
     database:set('welcome:'..msg.chat_id_,welcome[2])
  end
  
  if text:match("^ضع ترحيب (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
  local welcome = {string.match(text, "^(ضع ترحيب) (.*)$")} 
         send(msg.chat_id_, msg.id_, 1, '◯↲ تم وضع الترحيــب⇩:\nء✺━━━━━✺ء\n`'..welcome[2]..'`', 1, 'md')
     database:set('welcome:'..msg.chat_id_,welcome[2])
  end

          local text = msg.content_.text_:gsub('حذف الترحيب','del wlc')
  if text:match("^[Dd][Ee][Ll] [Ww][Ll][Cc]$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
                if database:get('lang:gp:'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '*Welcome Msg Has Been Deleted!*', 1, 'md')
       else 
                  send(msg.chat_id_, msg.id_, 1, '◯↲ تم حذف الترحيــــب✞', 1, 'md')
end
     database:del('welcome:'..msg.chat_id_)
end 
     -----------------------------------------------------------------------------------
  	if text:match("ضع قوانين (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local txt = {string.match(text, "(ضع قوانين) (.*)$")}
	database:set('bot:rules'..msg.chat_id_, txt[2])
         send(msg.chat_id_, msg.id_, 1, '◯↲ تم وضع القوانــين🎏', 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
  	if text:match("القوانين") then
	local rules = database:get('bot:rules'..msg.chat_id_)
         send(msg.chat_id_, msg.id_, 1, rules, 1, nil)
    end
	-----------------------------------------------------------------------------------------------
  	if text:match("^مطور السورس$") and is_sudo(msg) then
       sendContact(msg.chat_id_, msg.id_, 0, 1, nil, 9647805588437, 'آلقہٰٰيِٰہٰٰصۛہٰٰڕٰ_‏ᎯᏞᏫᎪᏕᏋᏒ', '(Test Version..!)', bot_id)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^ضع اسم (.*)$") and is_owner(msg.sender_user_id_, msg.chat_id_) then
	local txt = {string.match(text, "^(ضع اسم) (.*)$")} 
	     changetitle(msg.chat_id_, txt[2])
         send(msg.chat_id_, msg.id_, 1, '◯↲ تم تغييــر اسم المجمــوعه✔', 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]getme$") then
	function guser_by_reply(extra, result, success)
         --vardump(result)
    end
	     getUser(msg.sender_user_id_,guser_by_reply)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^ضع صوره$") and is_owner(msg.sender_user_id_, msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '◯↲ قم بإرسال الصوره 📩 ليتم حفظها❗️', 1, 'md')
		 database:set('bot:setphoto'..msg.chat_id_..':'..msg.sender_user_id_,true)
    end
	-----------------------------------------------------------------------------------------------
	local text = msg.content_.text_:gsub('منع','bad')
  if text:match("^[Bb][Aa][Dd] (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
  local filters = {string.match(text, "^([Bb][Aa][Dd]) (.*)$")} 
    local name = string.sub(filters[2], 1, 50)
          database:hset('bot:filters:'..msg.chat_id_, name, 'filtered')
                if database:get('lang:gp:'..msg.chat_id_) then
      send(msg.chat_id_, msg.id_, 1, "*New Word baded!*\n--> "..name.."", 1, 'md')
else 
        send(msg.chat_id_, msg.id_, 1, "📛↲ الكلمه 》 *"..name.."* 》 \n\n 📛↲ تــم ✅ منعهــا❗️", 1, 'md')
end
  end
  —---------------------------------------------------------------------------------------------
          local text = msg.content_.text_:gsub('الغاء منع','unbad')
  if text:match("^[Uu][Nn][Bb][Aa][Dd] (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
  local rws = {string.match(text, "^([Uu][Nn][Bb][Aa][Dd]) (.*)$")} 
    local name = string.sub(rws[2], 1, 50)
          database:hdel('bot:filters:'..msg.chat_id_, rws[2])
                if database:get('lang:gp:'..msg.chat_id_) then
      send(msg.chat_id_, msg.id_, 1, ""..rws[2].." *Removed From baded List!*", 1, 'md')
else 
        send(msg.chat_id_, msg.id_, 1, " 📛↲ الكلمــه 》* "..rws[2].."*》\n\n 📛↲ تــم ✅ الغاء منعهــا❗️ ", 1, 'md')
end
  end 
  —---------------------------------------------------------------------------------------------
          local text = msg.content_.text_:gsub('اذاعه','bc')
  if text:match("^bc (.*)$") and is_admin(msg.sender_user_id_, msg.chat_id_) then
    local gps = database:scard("bot:groups") or 0
    local gpss = database:smembers("bot:groups") or 0
  local rws = {string.match(text, "^(bc) (.*)$")} 
  for i=1, #gpss do
      send(gpss[i], 0, 1, rws[2], 1, 'html')
  end
                if database:get('lang:gp:'..msg.chat_id_) then
                   send(msg.chat_id_, msg.id_, 1, ' ', 1, 'md')
                   else
                     send(msg.chat_id_, msg.id_, 1, '🔷⇟ تــــم نشــر الرساله📬\n\n🔷⇟عدد الكروبات :〈*'..gps..'*〉', 1, 'md')
end
  end
  —---------------------------------------------------------------------------------------------
  if text:match("^[Gg][Rr][Oo][Uu][Pp][Ss]$") and is_admin(msg.sender_user_id_, msg.chat_id_) or text:match("^الكروبات$") and is_admin(msg.sender_user_id_, msg.chat_id_) then
    local gps = database:scard("bot:groups")
  local users = database:scard("bot:userss")
    local allmgs = database:get("bot:allmsgs")
                if database:get('lang:gp:'..msg.chat_id_) then
                   send(msg.chat_id_, msg.id_, 1, '*Groups :* '..gps..'', 1, 'md')
                 else
                   send(msg.chat_id_, msg.id_, 1, '*عــدد الكروبــات*: 「 *'..gps..'* 」', 1, 'md')
end
  end
  
if  text:match("^[Mm][Ss][Gg]$") or text:match("^رسائلي$") and msg.reply_to_message_id_ == 0  then
local user_msgs = database:get('user:msgs'..msg.chat_id_..':'..msg.sender_user_id_)
                if database:get('lang:gp:'..msg.chat_id_) then
       if not database:get('bot:id:mute'..msg.chat_id_) then
      send(msg.chat_id_, msg.id_, 1, "*Msgs : * "..user_msgs.."", 1, 'md')
      else 
        end
    else 
       if not database:get('bot:id:mute'..msg.chat_id_) then
      send(msg.chat_id_, msg.id_, 1, "🔺⇩اهــــلا عزيزي⚜️❗️\n\n🔻⇩ عــدد رسائلك: *"..user_msgs.."* ", 1, 'md')
      else 
        end
end
end 
	-----------------------------------------------------------------------------------------------
	if text:match('^تنظيف (%d+)$') and is_owner(msg.sender_user_id_, msg.chat_id_) then
  local matches = {string.match(text, "^(تنظيف) (%d+)$")}
   if msg.chat_id_:match("^-100") then
    if tonumber(matches[2]) > 100 or tonumber(matches[2]) < 1 then
      pm = '• <code> 🚀- العدد المسموح بــه اقل من ≪100≫ رسالــه🎈</code>'
    send(msg.chat_id_, msg.id_, 1, pm, 1, 'html')
                  else
      tdcli_function ({
     ID = "GetChatHistory",
       chat_id_ = msg.chat_id_,
          from_message_id_ = 0,
   offset_ = 0,
          limit_ = tonumber(matches[2])}, delmsg, nil)
      pm ='〖 <i>[ '..matches[2]..' ]</i>〗 <code>تم ✔ مسحهــا❗️</code>'
           send(msg.chat_id_, msg.id_, 1, pm, 1, 'html')
       end
        else pm ='<code> ⚜️- يوجــد خطأ❗️ <code> '
      send(msg.chat_id_, msg.id_, 1, pm, 1, 'html')
              end
            end 
  -----------------------------------------------------------------------------------------------
  if text:match("^( مغادره)(-%d+)$") and is_admin(msg.sender_user_id_, msg.chat_id_) then
  	local txt = {string.match(text, "^( مغادره) (-%d+)$")} 
	   send(msg.chat_id_, msg.id_, 1, '✺- المجموعــه\n '..txt[2]..' \n ✺-تــم الخروج منها🎐', 1, 'md')
	   send(txt[2], 0, 1, '✺- ليست من مجموعاتي عزيزي😴🖕', 1, 'md')
	   chat_leave(txt[2], bot_id)
  end
  -----------------------------------------------------------------------------------------------


  -----------------------------------------------------------------------------------------------
if text:match('تفعيل') and is_admin(msg.sender_user_id_, msg.chat_id_) then
       local txt = {string.match(text, "^تفعيل$")} 
       database:set("bot:charge:"..msg.chat_id_,true)
	   send(msg.chat_id_, msg.id_, 1, '✿↲ الايــدي: *'..result.sender_user_id_..'* \n\n✿↲ المُٰـٰٰٰـجمَوعـٰٰــه 🚩 مفـٰٰٰعٰٰــلْهّٰٰ ', 1, 'md')
	   for k,v in pairs(sudo_users) do
	      send(v, 0, 1, '✿↲ الايــدي: *'..result.sender_user_id_..'* \n\n✿↲ المُٰـٰٰٰـجمَوعـٰٰــه 🚩 مفـٰٰعٰــلْه ' ,  1,  'md')
       end
	   database:set("bot:enable:"..msg.chat_id_,true)
  end
  -----------------------------------------------------------------------------------------------
  if text:match('^تعطيل') and is_admin(msg.sender_user_id_, msg.chat_id_) then
       local txt = {string.match(text, "^تعطيل$")} 
       database:del("bot:charge:"..msg.chat_id_)
	   send(msg.chat_id_, msg.id_, 1, ' ✿↲ الايــدي: *'..result.sender_user_id_..'* \n\n✿↲ المُٰـٰٰٰـجمَوعـٰٰــه 🚩 معــٌَطلــه', 1, 'md')
	   for k,v in pairs(sudo_users) do
	      send(v, 0, 1, '✿↲ الايــدي: *'..result.sender_user_id_..'* \n\n✿↲ المُٰـٰٰٰـجمَوعـٰٰــه 🚩 معــٌَطلــه ' , 1, 'md')
       end
  end
	-----------------------------------------------------------------------------------------------
   if  text:match("^[Ii][Dd]$") and msg.reply_to_message_id_ == 0 or text:match("^ايدي$") and msg.reply_to_message_id_ == 0 then
local function getpro(extra, result, success)
local user_msgs = database:get('user:msgs'..msg.chat_id_..':'..msg.sender_user_id_)
   if result.photos_[0] then
      if is_sudo(msg) then
      if database:get('lang:gp:'..msg.chat_id_) then
      t = '`'
      else
      t = 'مطوري العزيز😻'
      end
      elseif is_admin(msg.sender_user_id_) then
      if database:get('lang:gp:'..msg.chat_id_) then
      t = '`'
      else
      t = 'ادمــــــن🐯'
      end
      elseif is_owner(msg.sender_user_id_, msg.chat_id_) then
      if database:get('lang:gp:'..msg.chat_id_) then
      t = '`'
      else
      t = 'المديــر🐼'
      end
      elseif is_mod(msg.sender_user_id_, msg.chat_id_) then
      if database:get('lang:gp:'..msg.chat_id_) then
      t = '`'
      else
      t = 'اداري🐱'
      end
      elseif is_vip(msg.sender_user_id_, msg.chat_id_) then
      if database:get('lang:gp:'..msg.chat_id_) then
      t = `'
      else
      t = '`'
      end
      else
      if database:get('lang:gp:'..msg.chat_id_) then
      t = '`'
      else
      t = ' عضــو 🐶'
      end
    end
         if not database:get('bot:id:mute'..msg.chat_id_) then
          if database:get('lang:gp:'..msg.chat_id_) then
            sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[0].sizes_[1].photo_.persistent_id_,"> Group ID : "..msg.chat_id_.."\n> Your ID : "..msg.sender_user_id_.."\n> UserName : "..get_info(msg.sender_user_id_).."\n> Your Rank : "..t.."\n> Msgs : "..user_msgs,msg.id_,msg.id_.."")
  else 
            sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[0].sizes_[1].photo_.persistent_id_,"🎴⇓ ايديك  : "..msg.sender_user_id_.."\n\n🎴⇓ رتبتك  : "..t.."\n\n🎴⇓ عدد رسائلك  : "..user_msgs,msg.id_,msg.id_.."")
end
else 
      end
   else
         if not database:get('bot:id:mute'..msg.chat_id_) then
          if database:get('lang:gp:'..msg.chat_id_) then
      send(msg.chat_id_, msg.id_, 1, "You Have'nt Profile Photo!!\n\n> *> Group ID :* "..msg.chat_id_.."\n*> Your ID :* "..msg.sender_user_id_.."\n*> UserName :* "..get_info(msg.sender_user_id_).."\n*> Msgs : *_"..user_msgs.."_", 1, 'md')
   else 
      send(msg.chat_id_, msg.id_, 1, "¤لا توجد صوره لحسابك¤\n\n🎴⇓ ايديك  : "..msg.sender_user_id_.."\n\n🎴⇓ رتبتك  : "..t.."\n\n🎴⇓ عدد رسائلك  : _"..user_msgs.."_", 1, 'md')
end
else 
      end
   end
   end
   tdcli_function ({
    ID = "GetUserProfilePhotos",
    user_id_ = msg.sender_user_id_,
    offset_ = 0,
    limit_ = 1
  }, getpro, nil)
end 
   -----------------------------------------------------------------------------------------------
   if text:match("^تثبيت$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
        local id = msg.id_
        local msgs = {[0] = id}
       pin(msg.chat_id_,msg.reply_to_message_id_,0)
	   database:set('pinnedmsg'..msg.chat_id_,msg.reply_to_message_id_)
   end
   -----------------------------------------------------------------------------------------------
   if text:match("^الغاء تثبيت$") and is_owner(msg.sender_user_id_, msg.chat_id_) then
         unpinmsg(msg.chat_id_)
         send(msg.chat_id_, msg.id_, 1, '◯↲ تــم ✔ الغاء تثبيت الرساله❗️', 1, 'md')
   end
   -----------------------------------------------------------------------------------------------
  if text:match("^الاوامر$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
   
   local text = [[
   🚩ســــــــــورس ⓚⓔⓔⓟⓔⓡ🚩
ٴ🔅─────◊◊◊─────🔅
⇚الاوامــــر كالتالي :-

📮م1 :《لعــــرض اوامر الحمايه⛓️》

📮م2 :《لعــــــرض اوامر الاداره👲》


📮م3 :《لعــــــرض اوامر الاخرى🛰️》

📮م4 :《لعــــــرض اوامر المطور🏌️》

ٴ🔅━━━━━🔅━━━━━🔅
🚦⇣مطــــور الــسورس: @llX8Xll

🚦⇣ قناة السورس: @keeper_ch 
]]
                send(msg.chat_id_, msg.id_, 1, text, 1, 'md')
   end 

-----------------------------------------------------------------------------------------------
  if text:match("^م1$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
   
   local text = [[
   🚩ســــــورس ⓚⓔⓔⓟⓔⓡ🚩
ٴ🔅────◊◊◊─────🔅
⇚اوامــــر الحمايـــــه استخــــدم :-【 قفل⇗للقفل】【 فتح⇗للفتح】

┓الروابــــــــــط🎢┏
┛الصــــــــــــور🌃┗

┓التوجــــــــيه📲┏
┛المتحــــــركه⛵️┗

┓الملــــــصقات✈️┏
┛الدردشــــــــه📝┗

┓الصــــــــــوت🗣️┏
┛الفــــــــــيديو📽️┗

┓التــــــــــعديل🖍️┏
┛المــــــــــواقع💻┗

┓البــوتــــــــات🎈┏
┛الاغــــــــــاني🎙️┗

┓العربــــــــــية📼┏
┛الانكليــــــزية📡┗

┓الانلايــــــــــن📣┏
┛المعــــــــــرف🔱┗
ٴ🔅━━━━━🔅━━━━━🔅
🚦⇣مطــــور الــسورس: @llX8Xll

🚦⇣ قناة السورس: @keeper_ch 
]]
                send(msg.chat_id_, msg.id_, 1, text, 1, 'md')
   end 
 --------------------------------------------------------------------------------------------- 
 if text:match("^م2$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
   
   local text = [[
   🚩ســــــورس ⓚⓔⓔⓟⓔⓡ🚩
ٴ🔅────◊◊◊─────🔅
⇚اوامــــر الاداره تســــــخدم :-
┐〖 بالــــرد آو المعــرف〗┌

🀄️⇓ رفع ادمن : لرفع ادمــن
🀄️⇓تنزيل ادمن :لتنزيل الادمن

🀄️⇓الادمنيه : لعرض الادمنيه
🀄️⇓المكتومين :لعرض المكتومين

🀄️⇓حظر : لحظر العضو
🀄️⇓الغاء الحظر : لألغاء الحظر

🀄️⇓كتم : لكتم العضو
🀄️⇓الغاء الكتم : لٱلغاء الكتم

🀄️⇓ايدي : لعرض الايدي
🀄️⇓رسائلي : لعرض الرسائل

🀄️⇓ضع صوره: لوضع صوره 
🀄️⇓مسح《البوتات،الادمنيه،قائمه المنع، المكتومين》: ليتم مسحهم

ٴ🔅━━━━━🔅━━━━━🔅
🚦⇣مطــــور الــسورس: @llX8Xll

🚦⇣ قناة السورس: @keeper_ch 
]]
                send(msg.chat_id_, msg.id_, 1, text, 1, 'md')
   end 
-----------------------------------------------------------------------------------------------
  if text:match("^م3$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
   
   local text = [[
   🚩ســــــورس ⓚⓔⓔⓟⓔⓡ🚩
ٴ🔅────◊◊◊─────🔅
⇚اوامــــر اخــرى تســــــخدم :-
┐〖 بالــــرد آو المعــرف〗┌

🎴⇓طرد : لطرد العظو
🎴⇓كول +الاسم : لتكرار الاسم

🎴⇓جهة المطور : لعرض اتصاله
🎴⇓ضع قوانين : لوض قوانين

🎴⇓ضع رابط : لوضع رابط
🎴⇓ضع اسم : لوضع اسم 

🎴⇓المطور : لعرض المطور
🎴⇓تنظيف+العدد : لتنظيف المجموعه

🎴⇓اضافه  : لاضافه العظو
🎴⇓الرابط : لعرض الرابط

🎴⇓المحظورين : لعرض المحظورين
🎴⇓صوره +رقم: بالرد ع العظو لجلبها

🎴⇓منع+ الكلمه : لمنع الكلمه
🎴⇓الغاء منع : لألغاء منعها
ٴ🔅━━━━━🔅━━━━━🔅
🚦⇣مطــــور الــسورس: @llX8Xll

🚦⇣ قناة السورس: @keeper_ch 
]]
                send(msg.chat_id_, msg.id_, 1, text, 1, 'md')
   end 
 --------------------------------------------------------------------------------------------- 
---------------------------------------------------------------------------------------------
   if text:match("^م4$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
   
   local text = [[
   🚩ســــــورس ⓚⓔⓔⓟⓔⓡ🚩
ٴ🔅────◊◊◊─────🔅
⇚اوامــــر المطــــور :-

🎐⇩تفعيل: لتفعيل البوت
🎐⇩تعطيل: لتعطيل البوت

🎐⇩رفع المدير: لرفع المدير
🎐⇩تنزيل المدير : لتنزيل المدير

🎐⇩اذاعه: لنشر في المجموعات
🎐⇩غادر: لأخراج البوت

🎐مغادره + ايدي المجموعه: لإخراجه

ٴ🔅━━━━━🔅━━━━━🔅
🚦⇣مطــــور الــسورس: @llX8Xll

🚦⇣ قناة السورس: @keeper_ch 
]]
                send(msg.chat_id_, msg.id_, 1, text, 1, 'md')
   end
   
  -----------------------------------------------------------------------------------------------
             
-----------------------------------------------------------------------------------------------
  if text:match("^المطور$") or text:match("^مطور$") or text:match("^المطورين$") or text:match("^مطورين$") or text:match("^مطور البوت$") then
   
   local text =  [[
اهــــلاً بــك فــي ســورس كــــيبر
 ✫مــطور البـɃŌȾـوت :⇓ [〘 آلقہٰٰيِٰہٰٰصۛہٰٰڕٰ_‏ᎯᏞᏫᎪᏕᏋᏒ 〙](https://telegram.me/llx8xll)
 [〘 بوت تواصل المحظورين 〙](https://telegram.me/lqlxlqlbot) [
〘 اشــُٰـتركِ قنــاةٌٰ الــبوتٌِ 〙](https://telegram.me/keeper_ch) [
〘 رمـٰـــــزيُـٰٰـاِت 〙](https://telegram.me/vip_rq) 

]]
                send(msg.chat_id_, msg.id_, 1, text, 1, 'html')
   end

if text:match("^ رابط الحذف$") or text:match("^رابط حذف$")  then
   
   local text =  [[
🔅￤ احذف حياتي 😅 انت مو مال تلي:
							

[ اضغــط هنا لحذف حسابك ]( https://telegram.org/deactivate )
]]
                send(msg.chat_id_, msg.id_, 1, text, 1, 'html')
   end
   end 
 --------------------------------------------------------------------------------------------- 
                          -- end code --
  -----------------------------------------------------------------------------------------------
  elseif (data.ID == "UpdateChat") then
    chat = data.chat_
    chats[chat.id_] = chat
  -----------------------------------------------------------------------------------------------
  elseif (data.ID == "UpdateMessageEdited") then
   local msg = data
  -- vardump(msg)
  	function get_msg_contact(extra, result, success)
	local text = (result.content_.text_ or result.content_.caption_)
    --vardump(result)
	if result.id_ and result.content_.text_ then
	database:set('bot:editid'..result.id_,result.content_.text_)
	end
  if not is_mod(result.sender_user_id_, result.chat_id_) then
   check_filter_words(result, text)
   if text:match("[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm].[Mm][Ee]") or
text:match("[Tt].[Mm][Ee]") or text:match("[Tt][Ll][Gg][Rr][Mm].[Mm][Ee]") then
   if database:get('bot:links:mute'..result.chat_id_) then
    local msgs = {[0] = data.message_id_}
       delete_msg(msg.chat_id_,msgs)
	end
   end
   	if text:match("[Hh][Tt][Tt][Pp][Ss]://") or text:match("[Hh][Tt][Tt][Pp]://") or text:match(".[Ii][Rr]") or text:match(".[Cc][Oo][Mm]") or text:match(".[Oo][Rr][Gg]") or text:match(".[Ii][Nn][Ff][Oo]") or text:match("[Ww][Ww][Ww].") or text:match(".[Tt][Kk]") then
   if database:get('bot:webpage:mute'..result.chat_id_) then
    local msgs = {[0] = data.message_id_}
       delete_msg(msg.chat_id_,msgs)
	end
   end
   if text:match("@") then
   if database:get('bot:tag:mute'..result.chat_id_) then
    local msgs = {[0] = data.message_id_}
       delete_msg(msg.chat_id_,msgs)
	end
   end
   	if text:match("#") then
   if database:get('bot:hashtag:mute'..result.chat_id_) then
    local msgs = {[0] = data.message_id_}
       delete_msg(msg.chat_id_,msgs)
	end
   end
   	if text:match("[\216-\219][\128-\191]") then
   if database:get('bot:arabic:mute'..result.chat_id_) then
    local msgs = {[0] = data.message_id_}
       delete_msg(msg.chat_id_,msgs)
	end
   end
   if text:match("[ASDFGHJKLQWERTYUIOPZXCVBNMasdfghjklqwertyuiopzxcvbnm]") then
   if database:get('bot:english:mute'..result.chat_id_) then
    local msgs = {[0] = data.message_id_}
       delete_msg(msg.chat_id_,msgs)
	end
   end
    end
	end
	if database:get('editmsg'..msg.chat_id_) == 'delmsg' then
        local id = msg.message_id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
              delete_msg(chat,msgs)
	elseif database:get('editmsg'..msg.chat_id_) == 'didam' then
	if database:get('bot:editid'..msg.message_id_) then
		local old_text = database:get('bot:editid'..msg.message_id_)
	    send(msg.chat_id_, msg.message_id_, 1, 'Ⓜ️- التعديــل ممنــوع 😸👌', 1, 'md')
	end
	end
    getMessage(msg.chat_id_, msg.message_id_,get_msg_contact)
  -----------------------------------------------------------------------------------------------
  elseif (data.ID == "UpdateOption" and data.name_ == "my_id") then
    tdcli_function ({ID="GetChats", offset_order_="9223372036854775807", offset_chat_id_=0, limit_=20}, dl_cb, nil)    
  end
end
end
