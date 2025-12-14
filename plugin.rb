# frozen_string_literal: true

# name: wb-allow-solved-pms
# about: Re-enables Discourse Solved "accept answer" inside PMs (optionally restricted to group messages).
# version: 0.2.0
# authors: Wiren Board
# url: https://github.com/kilpio-wb/wb-allow-solved-pms

enabled_site_setting :solved_pm_enabled

after_initialize do
  module ::WbAllowSolvedPms
    module GuardianPatch
      def can_accept_answer?(*args)
        topic = args[0]
        post  = args[1]

        # Keep core behavior for non-PMs (and for any unexpected call shapes)
        return super(*args) unless topic&.private_message?

        # Feature gate
        return false unless SiteSetting.solved_enabled
        return false unless SiteSetting.solved_pm_enabled

        # Must have a user + a target post
        return false unless authenticated?
        return false unless topic && post

        # Visibility + basic consistency
        return false unless post.topic_id == topic.id
        return false unless can_see?(topic) && can_see?(post)

        # --- Guardrails (mirror the "safe" parts of core expectations) ---

        # Only regular posts (no small-actions, etc.)
        if post.respond_to?(:post_type) && defined?(::Post) && Post.respond_to?(:types)
          return false unless post.post_type == Post.types[:regular]
        end

        # Never accept the first post as the solution
        return false if post.respond_to?(:post_number) && post.post_number.to_i == 1

        # No whispers
        return false if post.respond_to?(:whisper?) && post.whisper?

        # No deleted / trashed posts
        return false if post.respond_to?(:trashed?) && post.trashed?
        return false if post.respond_to?(:deleted_at) && post.deleted_at.present?

        # Respect closed/archived PMs (as per your “yes” requirement)
        return false if topic.respond_to?(:closed?) && topic.closed?
        return false if topic.respond_to?(:archived?) && topic.archived?

        # Avoid accepting system-user posts (optional but usually desired)
        if defined?(::Discourse) && Discourse.respond_to?(:system_user) && Discourse.system_user
          return false if post.respond_to?(:user_id) && post.user_id == Discourse.system_user.id
        end

        # --- Restrict which PM topics are eligible ---

        allowed_group_ids = solved_pm_topic_allowed_group_ids(topic)

        if solved_pm_target_group_ids.present?
          # Group inbox PMs only (must match configured target group list)
          return false if allowed_group_ids.blank?
          return false if (allowed_group_ids & solved_pm_target_group_ids).blank?
        else
          # If no target groups configured:
          # - allow group inbox PMs always
          # - allow 1:1 only if setting enabled
          if allowed_group_ids.blank?
            return false unless SiteSetting.solved_pm_allow_personal_messages
            return false unless one_to_one_pm?(topic)
          end
        end

        # --- Restrict who can mark solutions ---

        return true if is_staff?
        return true if solved_pm_actor_group_ids.any? { |gid| user.group_ids.include?(gid) }
        return true if SiteSetting.solved_pm_allow_topic_owner && topic.user_id == user.id

        false
      end

      private

      def one_to_one_pm?(topic)
        # 1:1 PM = no allowed groups AND exactly 2 allowed users
        return false if TopicAllowedGroup.where(topic_id: topic.id).exists?
        TopicAllowedUser.where(topic_id: topic.id).count == 2
      end

      def solved_pm_actor_group_ids
        @solved_pm_actor_group_ids ||= group_ids_from_setting(SiteSetting.solved_pm_actor_groups)
      end

      def solved_pm_target_group_ids
        @solved_pm_target_group_ids ||= group_ids_from_setting(SiteSetting.solved_pm_target_groups)
      end

      def solved_pm_topic_allowed_group_ids(topic)
        @solved_pm_topic_allowed_group_ids ||= {}
        @solved_pm_topic_allowed_group_ids[topic.id] ||= TopicAllowedGroup.where(topic_id: topic.id).pluck(:group_id)
      end

      def group_ids_from_setting(value)
        names = value.to_s.split("|").map(&:strip).reject(&:blank?)
        return [] if names.blank?
        Group.where(name: names).pluck(:id)
      end
    end
  end

  if ::Guardian.method_defined?(:can_accept_answer?)
    ::Guardian.prepend ::WbAllowSolvedPms::GuardianPatch
  else
    Rails.logger.warn("[wb-allow-solved-pms] Guardian#can_accept_answer? not found; is Solved enabled/bundled?")
  end
end
