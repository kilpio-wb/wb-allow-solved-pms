# frozen_string_literal: true

# name: wb-allow-solved-pms
# about: Re-enables Discourse Solved "accept answer" inside PMs (optionally restricted to group messages).
# version: 0.1.0
# authors: Wiren Board
# url: https://github.com/kilpio-wb/wb-allow-solved-pms

enabled_site_setting :solved_pm_enabled

after_initialize do
  module ::DiscourseSolvedInGroupMessages
    module GuardianPatch
      def can_accept_answer?(topic, post)
        # Keep core behavior for normal topics
        return super unless topic&.private_message?

        # Feature gate
        return false unless SiteSetting.solved_enabled
        return false unless SiteSetting.solved_pm_enabled

        # Basic sanity / safety checks (mirror core expectations)
        return false unless authenticated?
        return false unless topic && post
        return false if post.whisper?
        return false unless post.topic_id == topic.id
        return false unless can_see?(topic) && can_see?(post)

        # Restrict *which* PM topics are eligible (recommended: group inbox only)
        if solved_pm_target_group_ids.present?
          topic_group_ids = solved_pm_topic_allowed_group_ids(topic)
          return false if topic_group_ids.blank?
          return false if (topic_group_ids & solved_pm_target_group_ids).blank?
        else
          # If no target groups configured, optionally block 1:1 PMs
          unless SiteSetting.solved_pm_allow_personal_messages
            return false if solved_pm_topic_allowed_group_ids(topic).blank?
          end
        end

        # Restrict *who* can mark solutions
        return true if is_staff?
        return true if solved_pm_actor_group_ids.any? { |gid| user.group_ids.include?(gid) }
        return true if SiteSetting.solved_pm_allow_topic_owner && topic.user_id == user.id

        false
      end

      private

      def solved_pm_actor_group_ids
        @solved_pm_actor_group_ids ||= begin
          names = SiteSetting.solved_pm_actor_groups.to_s.split("|").map(&:strip).reject(&:blank?)
          names.present? ? Group.where(name: names).pluck(:id) : []
        end
      end

      def solved_pm_target_group_ids
        @solved_pm_target_group_ids ||= begin
          names = SiteSetting.solved_pm_target_groups.to_s.split("|").map(&:strip).reject(&:blank?)
          names.present? ? Group.where(name: names).pluck(:id) : []
        end
      end

      def solved_pm_topic_allowed_group_ids(topic)
        @solved_pm_topic_allowed_group_ids ||= {}
        @solved_pm_topic_allowed_group_ids[topic.id] ||= TopicAllowedGroup.where(topic_id: topic.id).pluck(:group_id)
      end
    end
  end

  if ::Guardian.method_defined?(:can_accept_answer?)
    ::Guardian.prepend ::DiscourseSolvedInGroupMessages::GuardianPatch
  else
    Rails.logger.warn(
      "[discourse-solved-in-group-messages] Guardian#can_accept_answer? not found; is Solved enabled/bundled?"
    )
  end
end
