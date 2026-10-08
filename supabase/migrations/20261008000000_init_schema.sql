-- ==============================================================================
-- CYCLECARE HEALTH APP - SUPABASE DATABASE MIGRATION
-- Migration: 20261008000000_init_schema.sql
-- Description: Khởi tạo toàn bộ schema, RLS policies, trigger updated_at và seed data
-- ==============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ------------------------------------------------------------------------------
-- 1. PROFILES TABLE
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT,
    birth_year INT,
    goal TEXT CHECK (goal IN ('track', 'conceive', 'pregnant', 'perimenopause')) DEFAULT 'track',
    avg_cycle_length INT DEFAULT 28 CHECK (avg_cycle_length >= 18 AND avg_cycle_length <= 45),
    avg_period_length INT DEFAULT 5 CHECK (avg_period_length >= 1 AND avg_period_length <= 15),
    is_anonymous BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
    ON public.profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id);

CREATE POLICY "Users can delete own profile"
    ON public.profiles FOR DELETE
    USING (auth.uid() = id);

-- ------------------------------------------------------------------------------
-- 2. CYCLES TABLE
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.cycles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    start_date DATE NOT NULL,
    end_date DATE,
    cycle_length INT CHECK (cycle_length IS NULL OR (cycle_length >= 10 AND cycle_length <= 100)),
    period_length INT CHECK (period_length IS NULL OR (period_length >= 1 AND period_length <= 20)),
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

ALTER TABLE public.cycles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own cycles"
    ON public.cycles FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own cycles"
    ON public.cycles FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own cycles"
    ON public.cycles FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own cycles"
    ON public.cycles FOR DELETE
    USING (auth.uid() = user_id);

-- ------------------------------------------------------------------------------
-- 3. DAILY_LOGS TABLE
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.daily_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    log_date DATE NOT NULL,
    mood TEXT,
    discharge TEXT,
    cramps_level INT CHECK (cramps_level >= 0 AND cramps_level <= 5),
    libido INT CHECK (libido >= 0 AND libido <= 5),
    sleep_hours NUMERIC(4, 2) CHECK (sleep_hours IS NULL OR (sleep_hours >= 0 AND sleep_hours <= 24)),
    sleep_quality INT CHECK (sleep_quality >= 1 AND sleep_quality <= 5),
    activity TEXT,
    symptoms TEXT[] DEFAULT '{}',
    note TEXT,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    UNIQUE(user_id, log_date)
);

ALTER TABLE public.daily_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own daily logs"
    ON public.daily_logs FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own daily logs"
    ON public.daily_logs FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own daily logs"
    ON public.daily_logs FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own daily logs"
    ON public.daily_logs FOR DELETE
    USING (auth.uid() = user_id);

-- ------------------------------------------------------------------------------
-- 4. PREGNANCIES TABLE
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.pregnancies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    lmp_date DATE NOT NULL,
    due_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT true NOT NULL,
    ended_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

ALTER TABLE public.pregnancies ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own pregnancies"
    ON public.pregnancies FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own pregnancies"
    ON public.pregnancies FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own pregnancies"
    ON public.pregnancies FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own pregnancies"
    ON public.pregnancies FOR DELETE
    USING (auth.uid() = user_id);

-- ------------------------------------------------------------------------------
-- 5. PARTNER_LINKS TABLE
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.partner_links (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    partner_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    invite_code TEXT UNIQUE NOT NULL,
    status TEXT CHECK (status IN ('pending', 'active', 'revoked')) DEFAULT 'pending' NOT NULL,
    share_mood BOOLEAN DEFAULT true NOT NULL,
    share_cycle BOOLEAN DEFAULT true NOT NULL,
    share_symptoms BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

ALTER TABLE public.partner_links ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view partner links they own or partner with"
    ON public.partner_links FOR SELECT
    USING (auth.uid() = owner_id OR auth.uid() = partner_id);

CREATE POLICY "Owner can insert partner link"
    ON public.partner_links FOR INSERT
    WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Owner or partner can update partner link"
    ON public.partner_links FOR UPDATE
    USING (auth.uid() = owner_id OR auth.uid() = partner_id);

-- Partner access policies for cycles and daily_logs:
CREATE POLICY "Partner can view shared cycles"
    ON public.cycles FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.partner_links pl
            WHERE pl.owner_id = cycles.user_id
              AND pl.partner_id = auth.uid()
              AND pl.status = 'active'
              AND pl.share_cycle = true
        )
    );

CREATE POLICY "Partner can view shared daily logs"
    ON public.daily_logs FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.partner_links pl
            WHERE pl.owner_id = daily_logs.user_id
              AND pl.partner_id = auth.uid()
              AND pl.status = 'active'
              AND (
                  pl.share_mood = true OR
                  pl.share_symptoms = true
              )
        )
    );

-- ------------------------------------------------------------------------------
-- 6. REMINDERS TABLE
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.reminders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type TEXT CHECK (type IN ('period', 'ovulation', 'pill', 'log')) NOT NULL,
    time TIME NOT NULL,
    enabled BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

ALTER TABLE public.reminders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own reminders"
    ON public.reminders FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- ------------------------------------------------------------------------------
-- 7. ARTICLES TABLE (Công khai đọc, chỉ admin/service_role ghi)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.articles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    category TEXT NOT NULL,
    locale TEXT DEFAULT 'vi' NOT NULL,
    is_premium BOOLEAN DEFAULT false NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

ALTER TABLE public.articles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view articles"
    ON public.articles FOR SELECT
    USING (true);

-- ------------------------------------------------------------------------------
-- 8. SUBSCRIPTIONS TABLE
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    plan TEXT NOT NULL,
    status TEXT NOT NULL,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own subscription"
    ON public.subscriptions FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own subscription"
    ON public.subscriptions FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- ------------------------------------------------------------------------------
-- UPDATED_AT TRIGGER FUNCTION
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_profiles_updated BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER on_cycles_updated BEFORE UPDATE ON public.cycles
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER on_daily_logs_updated BEFORE UPDATE ON public.daily_logs
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER on_pregnancies_updated BEFORE UPDATE ON public.pregnancies
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER on_partner_links_updated BEFORE UPDATE ON public.partner_links
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER on_reminders_updated BEFORE UPDATE ON public.reminders
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER on_subscriptions_updated BEFORE UPDATE ON public.subscriptions
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ------------------------------------------------------------------------------
-- SEED DATA (ARTICLES)
-- ------------------------------------------------------------------------------
INSERT INTO public.articles (title, body, category, locale, is_premium) VALUES
(
    'Hiểu Rõ 4 Pha Của Chu Kỳ Kinh Nguyệt',
    'Chu kỳ kinh nguyệt trung bình kéo dài 28 ngày và được chia thành 4 pha chính: 1. Pha hành kinh (Menstrual phase) khi niêm mạc tử cung bong ra; 2. Pha nang trứng (Follicular phase) khi nang trứng phát triển và estrogen tăng; 3. Pha rụng trứng (Ovulation phase) thường diễn ra vào ngày thứ 14 trước kỳ kinh tiếp theo; 4. Pha hoàng thể (Luteal phase) khi thể vàng tiết progesterone. Việc theo dõi từng pha giúp bạn tối ưu hóa chế độ dinh dưỡng, thể thao và kiểm soát cảm xúc.',
    'cycle',
    'vi',
    false
),
(
    'Cửa Sổ Thụ Thai & Cách Nhận Biết Thời Điểm Vàng',
    'Cửa sổ thụ thai (fertile window) bao gồm khoảng thời gian 5 ngày trước khi rụng trứng và ngày rụng trứng (tổng cộng 6 ngày). Tinh trùng có thể tồn tại trong đường sinh sản nữ tới 5 ngày trong điều kiện dịch nhầy thuận lợi. Dấu hiệu nhận biết rụng trứng bao gồm: dịch âm đạo dạng lòng trắng trứng sống, nhiệt độ cơ thể cơ bản tăng nhẹ, cảm giác căng tức ngực nhẹ hoặc đau nhói nhẹ vùng bụng dưới.',
    'fertility',
    'vi',
    false
),
(
    'Giảm Đau Bụng Kinh Tự Nhiên Không Cần Thuốc',
    'Đau bụng kinh (dysmenorrhea) thường do co thắt tử cung dưới tác động của prostaglandin. Bạn có thể giảm nhẹ cơn đau bằng cách: chườm ấm vùng bụng dưới bằng túi chườm (40°C), uống trà gừng ấm, tập yoga nhẹ nhàng với tư thế đứa trẻ (Child''s pose), bổ sung magie và vitamin B6 trong chế độ ăn hàng ngày.',
    'wellness',
    'vi',
    false
),
(
    'Hướng Dẫn Dinh Dưỡng 3 Tháng Đầu Thai Kỳ (Tam Cá Nguyệt 1)',
    'Trong 3 tháng đầu, việc bổ sung Acid Folic (400-600 mcg/ngày) là tối quan trọng để phòng ngừa dị tật ống thần kinh ở thai nhi. Đừng quá lo lắng về việc tăng cân trong giai đoạn này nếu bị ốm nghén, hãy chia nhỏ bữa ăn thành 5-6 bữa nhẹ, uống đủ nước và tránh thức ăn nhiều dầu mỡ hay có mùi nồng.',
    'pregnancy',
    'vi',
    true
),
(
    'Hiểu Về Giai Đoạn Tiền Mãn Kinh (Perimenopause)',
    'Tiền mãn kinh thường bắt đầu ở phụ nữ ngoài 40 tuổi và có thể kéo dài vài năm trước khi chính thức mãn kinh. Các dấu hiệu điển hình bao gồm: chu kỳ kinh thay đổi thất thường, bốc hỏa về đêm, rối loạn giấc ngủ, thay đổi tâm trạng và khô âm đạo. Duy trì lối sống lành mạnh và thăm khám phụ khoa định kỳ sẽ giúp giai đoạn này trôi qua êm dịu.',
    'menopause',
    'vi',
    true
),
(
    'Understanding the 4 Phases of Your Menstrual Cycle',
    'The menstrual cycle averages 28 days and comprises four distinct phases: menstruation, follicular phase, ovulation, and luteal phase. Tracking hormonal shifts helps align diet, fitness, and stress management with your natural biology.',
    'cycle',
    'en',
    false
),
(
    'Fertile Window: Everything You Need to Know',
    'Your fertile window consists of the five days before ovulation plus the day of ovulation itself. Sperm can survive up to five days in cervical mucus, making timed intercourse crucial when trying to conceive.',
    'fertility',
    'en',
    false
);
